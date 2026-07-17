//
// Copyright 2021 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import CallKit
import Foundation
import LibSignalClient
import SignalRingRTC
import SignalServiceKit
import UserNotifications
import os.log

class NSECallMessageHandler: CallMessageHandler {

    // MARK: Initializers

    init() {
        SwiftSingletons.register(self)
    }

    private var databaseStorage: SDSDatabaseStorage { SSKEnvironment.shared.databaseStorageRef }
    private var groupCallManager: GroupCallManager { SSKEnvironment.shared.groupCallManagerRef }
    private var identityManager: any OWSIdentityManager { DependenciesBridge.shared.identityManager }
    private var messagePipelineSupervisor: MessagePipelineSupervisor { SSKEnvironment.shared.messagePipelineSupervisorRef }
    private var notificationPresenter: NotificationPresenterImpl { SSKEnvironment.shared.notificationPresenterRef as! NotificationPresenterImpl }
    private var profileManager: any ProfileManager { SSKEnvironment.shared.profileManagerRef }
    private var tsAccountManager: any TSAccountManager { DependenciesBridge.shared.tsAccountManager }

    // MARK: - Call Handlers

    func receivedEnvelope(
        _ envelope: SSKProtoEnvelope,
        callEnvelope: CallEnvelopeType,
        from caller: (aci: Aci, deviceId: DeviceId),
        toLocalIdentity localIdentity: OWSIdentity,
        plaintextData: Data,
        wasReceivedByUD: Bool,
        sentAtTimestamp: UInt64,
        serverReceivedTimestamp: UInt64,
        serverDeliveryTimestamp: UInt64,
        tx: DBWriteTransaction,
    ) {
        let bufferSecondsForMainAppToAnswerRing: UInt64 = 10

        let serverReceivedTimestamp = serverReceivedTimestamp > 0 ? serverReceivedTimestamp : sentAtTimestamp
        let approxMessageAge = (serverDeliveryTimestamp - serverReceivedTimestamp)
        let messageAgeForRingRtc = approxMessageAge / UInt64.secondInMs + bufferSecondsForMainAppToAnswerRing

        switch callEnvelope {
        case .offer(let offer):
            guard let opaque = offer.opaque else {
                return
            }
            let callOfferHandler = CallOfferHandlerImpl(
                identityManager: identityManager,
                notificationPresenter: notificationPresenter,
                profileManager: profileManager,
                tsAccountManager: tsAccountManager,
            )
            let partialResult = callOfferHandler.startHandlingOffer(
                caller: caller.aci,
                sourceDevice: caller.deviceId,
                localIdentity: localIdentity,
                callId: offer.id,
                callType: offer.type ?? .offerAudioCall,
                sentAtTimestamp: sentAtTimestamp,
                tx: tx,
            )
            guard let partialResult else {
                return
            }

            let callType: CallMediaType
            switch offer.type ?? .offerAudioCall {
            case .offerAudioCall: callType = .audioCall
            case .offerVideoCall: callType = .videoCall
            }
            let isValid = isValidOfferMessage(
                opaque: opaque,
                messageAgeSec: messageAgeForRingRtc,
                callMediaType: callType,
            )
            guard isValid else {
                NSELogger.uncorrelated.warn("missed a call because it's not valid (according to RingRTC)")
                callOfferHandler.insertMissedCallInteraction(
                    for: offer.id,
                    in: partialResult.thread,
                    outcome: .incomingMissed,
                    callType: partialResult.offerMediaType,
                    sentAtTimestamp: sentAtTimestamp,
                    tx: tx,
                )
                return
            }

        case .opaque(let opaque):
            func validateGroupRing(groupId: Data, ringId: Int64) -> Bool {
                databaseStorage.read { transaction in
                    if SignalServiceAddress(caller.aci).isLocalAddress {
                        // Always trust our other devices (important for cancellations).
                        return true
                    }

                    guard let groupId = try? GroupIdentifier(contents: groupId) else {
                        owsFailDebug("discarding group ring \(ringId) from \(caller.aci) for invalid group identifier")
                        return false
                    }

                    guard let thread = TSGroupThread.fetch(forGroupId: groupId, tx: transaction) else {
                        owsFailDebug("discarding group ring \(ringId) from \(caller.aci) for unknown group")
                        return false
                    }

                    guard
                        GroupMessageProcessorManager.discardMode(
                            forMessageFrom: caller.aci,
                            groupId: groupId,
                            tx: transaction,
                        ) == .doNotDiscard
                    else {
                        NSELogger.uncorrelated.warn("discarding group ring \(ringId) from \(caller.aci)")
                        return false
                    }

                    guard thread.groupMembership.fullMembers.count <= RemoteConfig.current.maxGroupCallRingSize else {
                        NSELogger.uncorrelated.warn("discarding group ring \(ringId) from \(caller.aci) for too-large group")
                        return false
                    }

                    return true
                }
            }

            let shouldHandleExternally = { () -> Bool in
                guard opaque.urgency == .handleImmediately else {
                    return false
                }
                guard let opaqueData = opaque.data else {
                    return false
                }
                return isValidOpaqueRing(
                    opaqueCallMessage: opaqueData,
                    messageAgeSec: messageAgeForRingRtc,
                    validateGroupRing: validateGroupRing,
                )
            }()
            guard shouldHandleExternally else {
                NSELogger.uncorrelated.info("Ignoring opaque message; not a valid ring according to RingRTC.")
                return
            }

        case .answer, .iceUpdate, .hangup, .busy:
            NSELogger.uncorrelated.warn("Dropping call message; the main app should be connected")
            return
        }

        externallyHandleCallMessage(
            envelope: envelope,
            plaintextData: plaintextData,
            wasReceivedByUD: wasReceivedByUD,
            serverDeliveryTimestamp: serverDeliveryTimestamp,
            tx: tx,
        )
    }

    private func externallyHandleCallMessage(
        envelope: SSKProtoEnvelope,
        plaintextData: Data,
        wasReceivedByUD: Bool,
        serverDeliveryTimestamp: UInt64,
        tx: DBWriteTransaction,
    ) {
        do {
            let payload = try CallMessageRelay.enqueueCallMessageForMainApp(
                envelope: envelope,
                plaintextData: plaintextData,
                wasReceivedByUD: wasReceivedByUD,
                serverDeliveryTimestamp: serverDeliveryTimestamp,
                transaction: tx,
            )

            // We don't want to risk consuming any call messages that the main app needs to perform the call
            // We suspend message processing in our process to give the main app a chance to wake and take over
            let suspension = messagePipelineSupervisor.suspendMessageProcessing(for: .nseWakingUpApp(suspensionId: UUID(), payloadString: "\(payload)"))
            DispatchQueue.sharedUtility.asyncAfter(deadline: .now() + .seconds(10)) {
                suspension.invalidate()
            }

            NSELogger.uncorrelated.info("Notifying primary app of incoming call with push payload: \(payload)")
//            CXProvider.reportNewIncomingVoIPPushPayload(payload.payloadDict) { error in
//                if let error = error {
//                    owsFailDebug("Failed to notify main app of call message: \(error)")
//                } else {
//                    NSELogger.uncorrelated.info("Successfully notified main app of call message.")
//                }
//            }

            self.sendVoipPushViaServer(payload: payload)
        } catch {
            owsFailDebug("Failed to create relay voip payload for call message \(error)")
        }
    }

    private func sendVoipPushViaServer(payload: CallMessagePushPayload) {
        NSELogger.uncorrelated.info("Attempting to send VOIP push via server for payload: \(payload)")

        Task {
            do {
                // Send request to server with just the payload ID
                // Server will use authenticated device info to get VOIP token
                try await requestVoipPushFromServer(payloadId: payload.identifier)

                NSELogger.uncorrelated.info("Successfully requested VOIP push from server")

            } catch {
                NSELogger.uncorrelated.error("Failed to request VOIP push from server: \(error)")
            }
        }
    }


    private func requestVoipPushFromServer(payloadId: String) async throws {
        // Get server URL from TSConstants or configuration
        let baseURL = TSConstants.mainServiceIdentifiedURL
        guard let serverURL = URL(string: "\(baseURL)/v1/voip/push") else {
            throw NSError(domain: "InvalidURL", code: 1, userInfo: nil)
        }

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication headers - Signal uses Basic auth
        if let authCredentials = await getAuthenticationCredentials() {
            let credentialsString = "\(authCredentials.username):\(authCredentials.password)"
            let credentialsData = credentialsString.data(using: .utf8)!
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        } else {
            NSELogger.uncorrelated.warn("No authentication credentials available for VOIP push request")
        }

        let requestBody = [
            "callMessageRelayPayload": payloadId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 2, userInfo: nil)
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [
                "response": String(data: data, encoding: .utf8) ?? "No response data"
            ])
        }

        NSELogger.uncorrelated.info("VOIP push request successful, server response: \(httpResponse.statusCode)")
    }

    private func getAuthenticationCredentials() async -> (username: String, password: String)? {
        return await databaseStorage.awaitableWrite { transaction -> (username: String, password: String)? in
            guard let localIdentifiers = self.tsAccountManager.localIdentifiers(tx: transaction) else {
                return nil
            }

            // Signal uses ACI as username and auth password as password
            let username = localIdentifiers.aci.serviceIdUppercaseString

            // Get auth token from tsAccountManager
            guard let authToken = self.tsAccountManager.storedServerAuthToken(tx: transaction) else {
                return nil
            }

            return (username: username, password: authToken)
        }
    }

    func receivedGroupCallUpdateMessage(
        _ updateMessage: SSKProtoDataMessageGroupCallUpdate,
        forGroupId groupId: GroupIdentifier,
        serverReceivedTimestamp: UInt64,
    ) async {
        await groupCallManager.peekGroupCallAndUpdateThread(
            forGroupId: groupId,
            peekTrigger: .receivedGroupUpdateMessage(
                eraId: updateMessage.eraID,
                messageTimestamp: serverReceivedTimestamp,
            ),
        )
    }
}
