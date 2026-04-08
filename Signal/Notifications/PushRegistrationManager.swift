//
// Copyright 2017 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
public import PushKit
public import SignalServiceKit

public enum PushRegistrationError: Error {
    case assertionError(description: String)
    case pushNotSupported(description: String)
    case timeout
    case cancelled
}

/**
 * Singleton used to integrate with push notification services - registration and routing received remote notifications.
 */
public class PushRegistrationManager: NSObject, PKPushRegistryDelegate {

    private let appReadiness: AppReadiness

    init(appReadiness: AppReadiness) {
        self.appReadiness = appReadiness
        (preauthChallengeGuarantee, preauthChallengeFuture) = Guarantee<String>.pending()

        super.init()

        SwiftSingletons.register(self)
    }

    // Coordinates blocking of the calloutQueue while we wait for an incoming call
    private let incomingCallFuture = AtomicValue<GuaranteeFuture<Void>?>(nil, lock: .init())

    // Private callout queue that we can use to synchronously wait for our call to start
    // TODO: Rewrite call message routing to be able to synchronously report calls
    private static let calloutQueue = DispatchQueue(
        label: "org.signal.push-registration",
        autoreleaseFrequency: .workItem
    )
    private var calloutQueue: DispatchQueue { Self.calloutQueue }

    private var vanillaTokenPromise: Promise<Data>?
    private var vanillaTokenFuture: Future<Data>?

    private var voipTokenPromise: Promise<Data>?
    private var voipTokenFuture: Future<Data>?
    private var voipTokenPromiseCreationTime: Date?

    @MainActor
    private var voipRegistry: PKPushRegistry?

    private var preauthChallengeGuarantee: Guarantee<String>
    private var preauthChallengeFuture: GuaranteeFuture<String>

    // MARK: Public interface

    public func needsNotificationAuthorization() async -> Bool {
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        return notificationSettings.authorizationStatus == .notDetermined
    }

    public typealias ApnRegistrationId = RegistrationRequestFactory.ApnRegistrationId

    /// - parameter timeOutEventually: If the OS fails to get back to us with the apns token after
    /// we have requested it and significant time has passed, do we time out or keep waiting? Default to keep waiting.
    @MainActor
    public func requestPushTokens(
        forceRotation: Bool,
        timeOutEventually: Bool = false
    ) async throws -> ApnRegistrationId {
        Logger.info("")
        await self.registerUserNotificationSettings()

        #if targetEnvironment(simulator)
        if TSConstants.isUsingProductionService {
            throw PushRegistrationError.pushNotSupported(description: "Production APNs isn't supported on simulators.")
        }
        #endif

        let vanillaPushToken = try await registerForVanillaPushToken(forceRotation: forceRotation, timeOutEventually: timeOutEventually)

        // Also register for VoIP push token
        let voipPushToken = try await registerForVoipPushToken(
            forceRotation: forceRotation,
            timeOutEventually: timeOutEventually
        ).awaitable()

        return ApnRegistrationId(apnsToken: vanillaPushToken, voipToken: voipPushToken)
    }

    public func didFinishReportingIncomingCall() {
        incomingCallFuture.swap(nil)?.resolve()
    }

    // MARK: Vanilla push token

    /// Receives a pre-auth challenge token.
    ///
    /// Notably, this method is not responsible for requesting these tokens—that must be
    /// managed elsewhere. Before you request one, you should call this method.
    public func receivePreAuthChallengeToken() async -> String { await preauthChallengeGuarantee.awaitable() }

    /// Clears any existing pre-auth challenge token. If none exists, this method does nothing.
    public func clearPreAuthChallengeToken() {
        if preauthChallengeGuarantee.isSealed {
            (preauthChallengeGuarantee, preauthChallengeFuture) = Guarantee<String>.pending()
        }
    }

    @objc
    public func didReceiveVanillaPreAuthChallengeToken(_ challenge: String) {
        appReadiness.runNowOrWhenAppDidBecomeReadySync {
            AssertIsOnMainThread()
            Logger.info("received vanilla preauth challenge")
            self.preauthChallengeFuture.resolve(challenge)
        }
    }

    // Vanilla push token is obtained from the system via AppDelegate
    @objc
    public func didReceiveVanillaPushToken(_ tokenData: Data) {
        guard let vanillaTokenFuture = self.vanillaTokenFuture else {
            Logger.warn("System volunteered a push token even though we didn't request one. Syncing.")
            Task {
                do {
                    try await SyncPushTokensJob(mode: .normal).run()
                    Logger.info("Done syncing push tokens after system volunteered one.")
                } catch {
                    Logger.error("Failed to sync push tokens after system volunteered one.")
                }
            }
            return
        }

        vanillaTokenFuture.resolve(tokenData)
    }

    // Vanilla push token is obtained from the system via AppDelegate
    @objc
    public func didFailToReceiveVanillaPushToken(error: Error) {
        guard let vanillaTokenFuture = self.vanillaTokenFuture else {
            owsFailDebug("promise completion in \(#function) unexpectedly nil")
            return
        }

        vanillaTokenFuture.reject(error)
    }

    // MARK: PKPushRegistryDelegate - voIP Push Token

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        assertOnQueue(calloutQueue)
        owsAssertDebug(type == .voIP)

        // Synchronously wait until the app is ready.
        let appReady = DispatchSemaphore(value: 0)
        appReadiness.runNowOrWhenAppDidBecomeReadySync {
            appReady.signal()
        }
        appReady.wait()

        // This branch MUST start a CallKit call before it returns or else we risk
        // a PushKit penalty that may prevent us from handling future calls.
        let callRelayPayload = CallMessagePushPayload(payload.dictionaryPayload)
        if let callRelayPayload {
            Logger.info("Received VoIP push from the NSE: \(callRelayPayload)")
            let (guarantee, future) = Guarantee<Void>.pending()
            incomingCallFuture.set(future)
            AppEnvironment.shared.callService.earlyRingNextIncomingCall.set(true)
            CallMessageRelay.handleVoipPayload(callRelayPayload)
            Logger.info("Waiting for call to start: \(callRelayPayload)")
            guarantee.timeout(
                on: DispatchQueue.global(qos: .userInitiated),
                seconds: 5,
                substituteValue: ()
            ).wait()
            Logger.info("Returning back to PushKit. Good luck! \(callRelayPayload)")
            return
        }

        owsFailDebug("Ignoring PKPush without a valid payload.")
    }

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        Logger.info("PKPushRegistry didUpdate credentials called - type: \(type), registry: \(String(describing: registry))")

        guard type == .voIP else {
            Logger.warn("Received push credentials for unexpected type: \(type), expected: .voIP")
            return
        }

        let tokenString = credentials.token.hexadecimalString
        Logger.info("Received VoIP push token - length: \(credentials.token.count), token: \(tokenString.prefix(8))...")

        appReadiness.runNowOrWhenAppDidBecomeReadySync {
            AssertIsOnMainThread()
            Logger.info("App is ready, processing VoIP token - hasVoipTokenFuture: \(self.voipTokenFuture != nil)")

            guard let voipTokenFuture = self.voipTokenFuture else {
                Logger.warn("Received VoIP token without pending request. Current state - voipTokenPromise: \(self.voipTokenPromise != nil)")
                Logger.warn("This might be a system-initiated token refresh. Syncing tokens.")
                Task {
                    do {
                        try await SyncPushTokensJob(mode: .normal).run()
                        Logger.info("Done syncing push tokens after receiving unexpected VoIP token.")
                    } catch {
                        Logger.error("Failed to sync push tokens after receiving unexpected VoIP token: \(error)")
                    }
                }
                return
            }

            Logger.info("Resolving VoIP token future with received token")
            voipTokenFuture.resolve(credentials.token)
            self.voipTokenPromiseCreationTime = nil
        }
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        Logger.warn("Push token invalidated for type: \(type)")

        guard type == .voIP else {
            Logger.warn("Received token invalidation for unexpected type: \(type)")
            return
        }

        // Clear the stored VoIP token since it's no longer valid
        Task {
            await SSKEnvironment.shared.databaseStorageRef.awaitableWrite { tx in
                Logger.info("Clearing invalidated VoIP token")
                SSKEnvironment.shared.preferencesRef.setVoipToken(nil, tx: tx)
            }

            // Try to get a new VoIP token
            do {
                let _ = try await self.registerForVoipPushToken(forceRotation: true, timeOutEventually: true).awaitable()
                Logger.info("Successfully re-registered for VoIP push token after invalidation")

                // Sync the new token with the server
                try await SyncPushTokensJob(mode: .normal).run()
            } catch {
                Logger.error("Failed to re-register for VoIP push token after invalidation: \(error)")
            }
        }
    }

    // MARK: helpers

    // User notification settings must be registered *before* AppDelegate will
    // return any requested push tokens.
    public func registerUserNotificationSettings() async {
        await SSKEnvironment.shared.notificationPresenterRef.registerNotificationSettings()
    }

    /**
     * When users have disabled notifications and background fetch, the system hangs when returning a push token.
     * More specifically, after registering for remote notification, the app delegate calls neither
     * `didFailToRegisterForRemoteNotificationsWithError` nor `didRegisterForRemoteNotificationsWithDeviceToken`
     * This behavior is identical to what you'd see if we hadn't previously registered for user notification settings, though
     * in this case we've verified that we *have* properly registered notification settings.
     */
    @MainActor
    private func isSusceptibleToFailedPushRegistration() async -> Bool {

        // Only affects users who have disabled both: background refresh *and* notifications
        guard UIApplication.shared.backgroundRefreshStatus == .denied else {
            Logger.info("has backgroundRefreshStatus != .denied, not susceptible to push registration failure")
            return false
        }

        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()

        // This was ported from UIApplication.shared.currentUserNotificationSettings.types == [] so it only looks at these three settings.
        guard notificationSettings.alertSetting != .enabled && notificationSettings.badgeSetting != .enabled && notificationSettings.soundSetting != .enabled else {
            Logger.info("notificationSettings was not empty, not susceptible to push registration failure.")
            return false
        }

        Logger.warn("background refresh and notifications were disabled. Device is susceptible to push registration failure.")
        return true
    }

    @MainActor
    private func registerForVanillaPushToken(
        forceRotation: Bool,
        timeOutEventually: Bool
    ) async throws -> String {
        Logger.info("")

        if let vanillaTokenPromise {
            Logger.info("already pending promise for vanilla push token")
            return try await vanillaTokenPromise.awaitable().toHex()
        }

        // No pending vanilla token yet. Create a new promise
        let (promise, future) = Promise<Data>.pending()
        self.vanillaTokenPromise = promise
        defer { self.vanillaTokenPromise = nil }
        self.vanillaTokenFuture = future

        if forceRotation {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
        UIApplication.shared.registerForRemoteNotifications()

        if timeOutEventually {
            do {
                return try await withUncooperativeTimeout(seconds: 20, operation: {
                    return try await self._registerForVanillaPushToken(promise)
                })
            } catch is UncooperativeTimeoutError {
                throw PushRegistrationError.timeout
            }
        } else {
            return try await _registerForVanillaPushToken(promise)
        }
    }

    @MainActor
    private func _registerForVanillaPushToken(_ promise: Promise<Data>) async throws -> String {
        let pushTokenData: Data
        do {
            pushTokenData = try await withUncooperativeTimeout(seconds: 10, operation: {
                return try await promise.awaitable()
            })
        } catch is UncooperativeTimeoutError {
            if await self.isSusceptibleToFailedPushRegistration() {
                // If we've timed out on a device known to be susceptible to failures, quit trying
                // so the user doesn't remain indefinitely hung for no good reason.
                throw PushRegistrationError.pushNotSupported(description: "Device configuration disallows push notifications")
            } else {
                Logger.warn("Push registration is taking a while. Continuing to wait since this configuration is not known to fail push registration.")
                // Sometimes registration can just take a while.
                // If we're not on a device known to be susceptible to push registration failure,
                // just return the original promise.
                pushTokenData = try await promise.awaitable()
            }
        }
        if await self.isSusceptibleToFailedPushRegistration() {
            // Sentinel in case this bug is fixed.
            owsFailDebug("Device was unexpectedly able to complete push registration even though it was susceptible to failure.")
        }
        Logger.info("successfully registered for vanilla push notifications")
        return pushTokenData.toHex()
    }

    @MainActor
    private func registerForVoipPushToken(
        forceRotation: Bool,
        timeOutEventually: Bool
    ) -> Promise<String> {
        AssertIsOnMainThread()
        Logger.info("Registering for VoIP push token - forceRotation: \(forceRotation), timeOutEventually: \(timeOutEventually)")

        // Check if there's already a pending promise
        if let existingPromise = self.voipTokenPromise {
            Logger.info("Found existing VOIP token promise - isSealed: \(existingPromise.isSealed), forceRotation: \(forceRotation)")

            if existingPromise.isSealed {
                // Promise is sealed (completed/failed), clear it and create new one
                Logger.warn("Clearing sealed VOIP token promise")
                self.voipTokenPromise = nil
                self.voipTokenFuture = nil
                self.voipTokenPromiseCreationTime = nil
            } else if forceRotation {
                // Force rotation requested, clear existing promise
                Logger.warn("Force rotation requested, clearing existing VOIP token promise")
                // Reject the existing promise to prevent hanging
                if let existingFuture = self.voipTokenFuture {
                    existingFuture.reject(PushRegistrationError.cancelled)
                }
                self.voipTokenPromise = nil
                self.voipTokenFuture = nil
                self.voipTokenPromiseCreationTime = nil
            } else {
                // Promise is not sealed, so it must be pending
                // Check if this promise has been pending for too long (over 30 seconds)
                let maxPendingTime: TimeInterval = 30.0
                if let promiseCreationTime = self.voipTokenPromiseCreationTime,
                   Date().timeIntervalSince(promiseCreationTime) > maxPendingTime {
                    Logger.error("VOIP token promise has been pending for over \(maxPendingTime) seconds, clearing it")
                    if let existingFuture = self.voipTokenFuture {
                        existingFuture.reject(PushRegistrationError.timeout)
                    }
                    self.voipTokenPromise = nil
                    self.voipTokenFuture = nil
                    self.voipTokenPromiseCreationTime = nil
                } else {
                    // Return existing pending promise
                    Logger.info("already pending promise for VoIP push token")
                    return existingPromise.map { $0.hexadecimalString }
                }
            }
        }

        // Check app capabilities and permissions
        Logger.info("Checking VoIP capabilities - isSimulator: \(Platform.isSimulator), isProductionService: \(TSConstants.isUsingProductionService)")

        // Diagnose current state
        diagnoseVoipPushState()

        // No pending VoIP token yet. Create a new promise
        let (promise, future) = Promise<Data>.pending()
        self.voipTokenPromise = promise
        self.voipTokenFuture = future
        self.voipTokenPromiseCreationTime = Date()

        Logger.info("Created new VoIP token promise and future")

        // Create VoIP registry if necessary and request token
        createVoipRegistryIfNecessary()

        // Check if we already have a token from the registry
        if let existingToken = voipRegistry?.pushToken(for: .voIP) {
            Logger.info("Found existing VoIP token in registry, resolving immediately: \(existingToken.hexadecimalString.prefix(8))...")
            future.resolve(existingToken)
            self.voipTokenPromiseCreationTime = nil

            let returnedPromise = promise.map { $0.hexadecimalString }
            if !timeOutEventually {
                Logger.info("Returning VoIP token promise without eventual timeout (existing token)")
                return returnedPromise
            }
            Logger.info("Returning VoIP token promise with 20s eventual timeout (existing token)")
            return returnedPromise.timeout(seconds: 20, timeoutErrorBlock: {
                Logger.error("VoIP token registration hit final 20s timeout (existing token)")
                return PushRegistrationError.timeout
            })
        }

        // Force re-registration if requested
        if forceRotation {
            Logger.info("Force rotation requested - clearing existing VoIP registry")
            voipRegistry?.delegate = nil
            voipRegistry = nil
            createVoipRegistryIfNecessary()
        }

        let returnedPromise = firstly {
            Logger.info("Starting VoIP token promise chain with 10s timeout")
            return promise.timeout(seconds: 10, description: "Register for VoIP push token") {
                Logger.warn("VoIP token registration hit 10s timeout")
                return PushRegistrationError.timeout
            }
        }.recover { error -> Promise<Data> in
            switch error {
            case PushRegistrationError.timeout:
                Logger.warn("VoIP push registration timed out after 10s, but continuing to wait for system callback")
                Logger.info("Current VoIP registry state: exists=\(self.voipRegistry != nil), delegate=\(String(describing: self.voipRegistry?.delegate))")
                return promise
            default:
                Logger.error("VoIP push registration failed with error: \(error)")
                throw error
            }
        }.then { (pushTokenData: Data) -> Promise<String> in
            Logger.info("successfully registered for VoIP push notifications - token length: \(pushTokenData.count), token: \(pushTokenData.hexadecimalString.prefix(8))...")
            return Promise.value(pushTokenData.hexadecimalString)
        }.ensure {
            Logger.info("Cleaning up VoIP token promise")
            self.voipTokenPromise = nil
            self.voipTokenPromiseCreationTime = nil
        }

        guard timeOutEventually else {
            Logger.info("Returning VoIP token promise without eventual timeout")
            return returnedPromise
        }
        Logger.info("Returning VoIP token promise with 20s eventual timeout")
        return returnedPromise.timeout(seconds: 20, timeoutErrorBlock: {
            Logger.error("VoIP token registration hit final 20s timeout")
            return PushRegistrationError.timeout
        })
    }

    // MARK: - VoIP Token Management

    /// Forces a refresh of the VoIP push token
    @MainActor
    public func refreshVoipToken() -> Promise<String> {
        Logger.info("Forcing VoIP token refresh")
        return registerForVoipPushToken(forceRotation: true, timeOutEventually: true)
    }

    /// Checks if VoIP push is available and properly configured
    @MainActor
    public func isVoipPushAvailable() -> Bool {
        guard !TSConstants.isUsingProductionService || !Platform.isSimulator else {
            return false
        }
        return voipRegistry != nil
    }

    /// Clears all VoIP push related data
    @MainActor
    public func clearVoipPushData() {
        Task {
            await SSKEnvironment.shared.databaseStorageRef.awaitableWrite { tx in
                Logger.warn("Clearing all VoIP push data")
                SSKEnvironment.shared.preferencesRef.setVoipToken(nil, tx: tx)
            }
        }

        // Reset the VoIP registry
        voipRegistry?.delegate = nil
        voipRegistry = nil
        voipTokenPromise = nil
        voipTokenFuture = nil
        voipTokenPromiseCreationTime = nil
    }

    /// Diagnoses VoIP push configuration and state
    @MainActor
    public func diagnoseVoipPushState() {
        Logger.info("=== VoIP Push Diagnosis ===")

        // Check background modes in Info.plist
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        Logger.info("Background modes: \(backgroundModes)")
        Logger.info("VoIP background mode enabled: \(backgroundModes.contains("voip"))")

        // Check app state and permissions
        Logger.info("Current app state: \(UIApplication.shared.applicationState.rawValue)")
        Logger.info("Background refresh status: \(UIApplication.shared.backgroundRefreshStatus.rawValue)")

        // Check VoIP registry state
        if let registry = voipRegistry {
            Logger.info("VoIP registry exists: desiredPushTypes=\(String(describing: registry.desiredPushTypes)), delegate=\(String(describing: registry.delegate))")

            // Check for existing token
            let existingToken = registry.pushToken(for: .voIP)
            if let token = existingToken {
                Logger.info("VoIP registry has existing token: \(token.hexadecimalString.prefix(8))...")
            } else {
                Logger.warn("VoIP registry has no existing token")
            }
        } else {
            Logger.warn("No VoIP registry exists")
        }

        // Check promise state
        Logger.info("Current promise state - voipTokenPromise: \(voipTokenPromise != nil), voipTokenFuture: \(voipTokenFuture != nil)")

        // Check stored preferences
        let storedVoipToken = SSKEnvironment.shared.preferencesRef.voipToken
        Logger.info("Stored VoIP token: \(redact(storedVoipToken))")

        Logger.info("=== End VoIP Push Diagnosis ===")
    }

    @MainActor
    private func createVoipRegistryIfNecessary() {
        AssertIsOnMainThread()

        guard voipRegistry == nil else {
            Logger.info("VoIP registry already exists, skipping creation")
            return
        }

        Logger.info("Creating new PKPushRegistry for VoIP")
        let voipRegistry = PKPushRegistry(queue: calloutQueue)
        self.voipRegistry = voipRegistry
        voipRegistry.desiredPushTypes = [.voIP]
        voipRegistry.delegate = self

        Logger.info("PKPushRegistry created and configured: desiredPushTypes=[\(String(describing: voipRegistry.desiredPushTypes))], delegate=\(String(describing: voipRegistry.delegate))")

        // Log current push token if available
        if let existingToken = voipRegistry.pushToken(for: .voIP) {
            Logger.info("PKPushRegistry already has existing VoIP token: \(existingToken.hexadecimalString.prefix(8))...")
        } else {
            Logger.warn("PKPushRegistry has no existing VoIP token")
        }
    }

    private func redact(_ string: String?) -> String {
        guard let string = string else { return "nil" }
        return "\(string.prefix(2))…\(string.suffix(2))"
    }
}
