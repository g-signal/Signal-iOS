//
// Copyright 2016 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import SignalServiceKit

class SyncPushTokensJob: NSObject {
    enum Mode {
        case normal
        case forceRotation
        case rotateIfEligible
    }

    private let mode: Mode

    public let auth: ChatServiceAuth

    init(mode: Mode, auth: ChatServiceAuth = .implicit()) {
        self.mode = mode
        self.auth = auth
    }

    private static let hasUploadedTokensOnce = AtomicBool(false, lock: .sharedGlobal)

    func run() async throws {
        switch mode {
        case .normal:
            // Don't rotate.
            return try await run(shouldRotateAPNSToken: false)
        case .forceRotation:
            // Always rotate
            return try await run(shouldRotateAPNSToken: true)
        case .rotateIfEligible:
            let shouldRotate = SSKEnvironment.shared.databaseStorageRef.read { tx -> Bool in
                return APNSRotationStore.canRotateAPNSToken(transaction: tx)
            }
            guard shouldRotate else {
                // If we aren't rotating, no-op.
                return
            }
            return try await run(shouldRotateAPNSToken: true)
        }
    }

    public typealias ApnRegistrationId = RegistrationRequestFactory.ApnRegistrationId

    private func run(shouldRotateAPNSToken: Bool) async throws {
        Logger.info("Starting SyncPushTokensJob - shouldRotateAPNSToken: \(shouldRotateAPNSToken)")

        Logger.info("Requesting push tokens from PushRegistrationManager...")
        let regResult = try await AppEnvironment.shared.pushRegistrationManagerRef.requestPushTokens(forceRotation: shouldRotateAPNSToken).awaitable()

        Logger.info("Received push tokens from PushRegistrationManager - apnsToken: \(redact(regResult.apnsToken)), voipToken: \(redact(regResult.voipToken))")

        await SSKEnvironment.shared.databaseStorageRef.awaitableWrite { tx in
            if shouldRotateAPNSToken {
                Logger.info("Marking APNS token as rotated in database")
                APNSRotationStore.didRotateAPNSToken(transaction: tx)
            }
        }

        let pushToken = regResult.apnsToken
        let voipToken = regResult.voipToken

        Logger.info("Extracted tokens - pushToken: \(redact(pushToken)), voipToken: \(redact(voipToken))")

        // Get current stored tokens for comparison
        let currentPushToken = SSKEnvironment.shared.preferencesRef.pushToken
        let currentVoipToken = SSKEnvironment.shared.preferencesRef.voipToken

        Logger.info("Current stored tokens - pushToken: \(redact(currentPushToken)), voipToken: \(redact(currentVoipToken))")

        let reason: String

        if currentPushToken != pushToken {
            reason = "changed"
            Logger.info("Push token changed: \(redact(currentPushToken)) -> \(redact(pushToken))")
        } else if currentVoipToken != voipToken {
            reason = "voip_changed"
            Logger.info("VoIP token changed: \(redact(currentVoipToken)) -> \(redact(voipToken))")
        } else if AppVersionImpl.shared.lastAppVersion != AppVersionImpl.shared.currentAppVersion {
            reason = "upgraded"
            Logger.info("App version changed: \(AppVersionImpl.shared.lastAppVersion ?? "nil") -> \(AppVersionImpl.shared.currentAppVersion)")
        } else if !Self.hasUploadedTokensOnce.get() {
            reason = "launched"
            Logger.info("First time uploading tokens since app launch")
        } else {
            Logger.info("No reason to upload tokens - all are same as stored: pushToken: \(redact(pushToken)), voipToken: \(redact(voipToken))")
            return
        }

        Logger.warn("Uploading push tokens; reason: \(reason), pushToken: \(redact(pushToken)), voipToken: \(redact(voipToken))")
        try await self.updatePushTokens(pushToken: pushToken, voipToken: voipToken, auth: auth)

        await recordPushTokensLocally(pushToken: pushToken, voipToken: voipToken)

        Self.hasUploadedTokensOnce.set(true)
        Logger.info("SyncPushTokensJob completed successfully")
    }

    class func run(mode: Mode = .normal) {
        Task {
            do {
                try await SyncPushTokensJob(mode: mode).run()
            } catch {
                Logger.error("Error: \(error).")
            }
        }
    }

    private func recordPushTokensLocally(pushToken: String, voipToken: String?) async {
        assert(!Thread.isMainThread)

        await SSKEnvironment.shared.databaseStorageRef.awaitableWrite { tx in
            Logger.warn("Recording push tokens locally. pushToken: \(redact(pushToken)), voipToken: \(redact(voipToken))")

            if pushToken != SSKEnvironment.shared.preferencesRef.getPushToken(tx: tx) {
                Logger.info("Recording new plain push token")
                SSKEnvironment.shared.preferencesRef.setPushToken(pushToken, tx: tx)
            }

            if voipToken != SSKEnvironment.shared.preferencesRef.getVoipToken(tx: tx) {
                Logger.info("Recording new VoIP push token")
                SSKEnvironment.shared.preferencesRef.setVoipToken(voipToken, tx: tx)
            }
        }
    }

    // MARK: - Requests

    func updatePushTokens(pushToken: String, voipToken: String?, auth: ChatServiceAuth) async throws {
        Logger.info("Starting push token upload - pushToken: \(redact(pushToken)), voipToken: \(redact(voipToken))")

        // Upload regular push token
        do {
            Logger.info("Uploading regular push token...")
            try await Retry.performWithBackoff(maxAttempts: 3) {
                let request = OWSRequestFactory.registerForPushRequest(apnsToken: pushToken)
                var authedRequest = request
                authedRequest.auth = .identified(auth)

                Logger.info("Regular push API request - URL: \(request.url.absoluteString), method: \(request.method)")

                let response = try await SSKEnvironment.shared.networkManagerRef.asyncRequest(authedRequest, canUseWebSocket: false)

                Logger.info("Regular push API response - statusCode: \(response.responseStatusCode), body: \(String(data: response.responseBodyData ?? Data(), encoding: .utf8) ?? "nil")")
            }
            Logger.info("Regular push token uploaded successfully")
        } catch {
            Logger.error("Failed to upload regular push token: \(error)")
            throw error
        }

        // Upload VoIP token if available
        if let voipToken = voipToken {
            do {
                Logger.info("Uploading VoIP token...")
                try await Retry.performWithBackoff(maxAttempts: 3) {
                    let request = OWSRequestFactory.registerForVoipPushRequest(voipToken: voipToken)
                    var authedRequest = request
                    authedRequest.auth = .identified(auth)

                    Logger.info("VoIP push API request - URL: \(request.url.absoluteString), method: \(request.method)")

                    let response = try await SSKEnvironment.shared.networkManagerRef.asyncRequest(authedRequest, canUseWebSocket: false)

                    Logger.info("VoIP push API response - statusCode: \(response.responseStatusCode), body: \(String(data: response.responseBodyData ?? Data(), encoding: .utf8) ?? "nil")")
                }
                Logger.info("VoIP token uploaded successfully")
            } catch {
                Logger.error("Failed to upload VoIP token: \(error)")
                throw error
            }
        } else {
            Logger.warn("No VoIP token to upload - voipToken is nil")
        }

        Logger.info("Push token upload completed successfully")
    }
}

private func redact(_ string: String?) -> String {
    guard let string = string else { return "nil" }
#if DEBUG
    return string
#else
    return "\(string.prefix(2))…\(string.suffix(2))"
#endif
}
