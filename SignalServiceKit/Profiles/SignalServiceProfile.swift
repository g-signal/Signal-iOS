//
// Copyright 2018 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
public import LibSignalClient

/// Represents a user's profile as fetched from the service.
///
/// All non-capability fields are encrypted, and if present should be decrypted
/// using this user's profile key.
public class SignalServiceProfile {
    private struct ValidationError: Error, CustomStringConvertible {
        let description: String
    }

    public struct Capabilities {
        fileprivate static let dummyCapabilityKey = "dummy"

        /// A dummy capability that keeps this struct non-empty. If it were
        /// empty, the compiler would complain about much of the code in here
        /// being unused...which is true! But, we want to keep it around for the
        /// future, when we may add new capabilities.
        public let dummyCapability: Bool
    }

    public let serviceId: ServiceId
    public let identityKey: IdentityKey
    public let profileNameEncrypted: Data?
    public let bioEncrypted: Data?
    public let bioEmojiEncrypted: Data?
    public let avatarUrlPath: String?
    public let paymentAddressEncrypted: Data?
    public let unidentifiedAccessVerifier: Data?
    public let hasUnrestrictedUnidentifiedAccess: Bool
    public let credential: Data?
    public let badges: [(OWSUserProfileBadgeInfo, ProfileBadge)]
    public let phoneNumberSharingEncrypted: Data?
    public let gextTags: [GExtTag]?
    public let gextRobot: GExtRobot?

    public let capabilities: Capabilities

    private init(
        serviceId: ServiceId,
        identityKey: IdentityKey,
        profileNameEncrypted: Data?,
        bioEncrypted: Data?,
        bioEmojiEncrypted: Data?,
        avatarUrlPath: String?,
        paymentAddressEncrypted: Data?,
        unidentifiedAccessVerifier: Data?,
        hasUnrestrictedUnidentifiedAccess: Bool,
        credential: Data?,
        badges: [(OWSUserProfileBadgeInfo, ProfileBadge)],
        phoneNumberSharingEncrypted: Data?,
        gextTags: [GExtTag]?,
        gextRobot: GExtRobot?,
        capabilities: Capabilities,
    ) {
        self.serviceId = serviceId
        self.identityKey = identityKey
        self.profileNameEncrypted = profileNameEncrypted
        self.bioEncrypted = bioEncrypted
        self.bioEmojiEncrypted = bioEmojiEncrypted
        self.avatarUrlPath = avatarUrlPath
        self.paymentAddressEncrypted = paymentAddressEncrypted
        self.unidentifiedAccessVerifier = unidentifiedAccessVerifier
        self.hasUnrestrictedUnidentifiedAccess = hasUnrestrictedUnidentifiedAccess
        self.credential = credential
        self.badges = badges
        self.phoneNumberSharingEncrypted = phoneNumberSharingEncrypted
        self.gextTags = gextTags
        self.gextRobot = gextRobot
        self.capabilities = capabilities
    }

    public static func fromResponse(serviceId: ServiceId, params: ParamParser) throws -> SignalServiceProfile {
        do {
            let identityKey = try IdentityKey(bytes: try params.requiredBase64EncodedData(key: "identityKey"))
            let profileNameEncrypted = try params.optionalBase64EncodedData(key: "name")
            let bioEncrypted = try params.optionalBase64EncodedData(key: "about")
            let bioEmojiEncrypted = try params.optionalBase64EncodedData(key: "aboutEmoji")
            let avatarUrlPath: String? = try params.optional(key: "avatar")
            let paymentAddressEncrypted = try params.optionalBase64EncodedData(key: "paymentAddress")
            let unidentifiedAccessVerifier = try params.optionalBase64EncodedData(key: "unidentifiedAccess")
            let hasUnrestrictedUnidentifiedAccess: Bool = try params.optional(key: "unrestrictedUnidentifiedAccess") ?? false
            let credential = try params.optionalBase64EncodedData(key: "credential")
            let badges: [(OWSUserProfileBadgeInfo, ProfileBadge)] = try parseBadges(params: params)
            let phoneNumberSharingEncrypted = try params.optionalBase64EncodedData(key: "phoneNumberSharing")
            let gextTags: [GExtTag]? = try parseGExtTags(params: params)
            let gextRobot: GExtRobot? = try parseGExtRobot(params: params)
            let capabilities: Capabilities = try parseCapabilities(params: params)

            return SignalServiceProfile(
                serviceId: serviceId,
                identityKey: identityKey,
                profileNameEncrypted: profileNameEncrypted,
                bioEncrypted: bioEncrypted,
                bioEmojiEncrypted: bioEmojiEncrypted,
                avatarUrlPath: avatarUrlPath,
                paymentAddressEncrypted: paymentAddressEncrypted,
                unidentifiedAccessVerifier: unidentifiedAccessVerifier,
                hasUnrestrictedUnidentifiedAccess: hasUnrestrictedUnidentifiedAccess,
                credential: credential,
                badges: badges,
                phoneNumberSharingEncrypted: phoneNumberSharingEncrypted,
                gextTags: gextTags,
                gextRobot: gextRobot,
                capabilities: capabilities,
            )
        } catch let error {
            throw ValidationError(description: "Failed to parse profile JSON: \(error)")
        }
    }

    private static func parseBadges(params: ParamParser) throws -> [(OWSUserProfileBadgeInfo, ProfileBadge)] {
        if let badgeArray: [[String: Any]] = try params.optional(key: "badges") {
            return try badgeArray.compactMap { badgeDict in
                let badgeParams = ParamParser(badgeDict)
                let isVisible: Bool? = try badgeParams.optional(key: "visible")
                let expiration: TimeInterval? = try badgeParams.optional(key: "expiration")
                let expirationMills = expiration.flatMap { UInt64($0 * 1000) }

                let badge = try ProfileBadge(jsonDictionary: badgeDict)
                let badgeMetadata: OWSUserProfileBadgeInfo
                if let expirationMills, let isVisible {
                    badgeMetadata = OWSUserProfileBadgeInfo(badgeId: badge.id, expiration: expirationMills, isVisible: isVisible)
                } else {
                    badgeMetadata = OWSUserProfileBadgeInfo(badgeId: badge.id)
                }
                return (badgeMetadata, badge)
            }
        } else {
            return []
        }
    }

    private static func parseCapabilities(params: ParamParser) throws -> Capabilities {
        guard let capabilitiesDict: [String: Any] = try params.required(key: "capabilities") else {
            throw ValidationError(description: "Missing or invalid capabilities JSON!")
        }

        return Capabilities(
            dummyCapability: parseCapabilityFlag(
                capabilitiesParser: ParamParser(capabilitiesDict),
                capabilityKey: Capabilities.dummyCapabilityKey,
            ),
        )
    }

    private static func parseGExtTags(params: ParamParser) throws -> [GExtTag]? {
        guard let gextTagsArray: [[String: Any]] = try params.optional(key: "gextTags") else {
            return nil
        }

        var result: [GExtTag] = []
        for tagDict in gextTagsArray {
            let tagParams = ParamParser(dictionary: tagDict)

            do {
                guard let tagIdString: String = try tagParams.required(key: "tagId"),
                      let tagType: Int = try tagParams.required(key: "tagType") else {
                    continue
                }

                let text: String? = try tagParams.optional(key: "text")
                let imgBase64: String? = try tagParams.optional(key: "imgBase64")
                let cssBackgroundColor: String? = try tagParams.optional(key: "cssBackgroundColor")
                let cssColor: String? = try tagParams.optional(key: "cssColor")
                let cssBorderColor: String? = try tagParams.optional(key: "cssBorderColor")
                let cssBorderStyle: String? = try tagParams.optional(key: "cssBorderStyle")
                let cssOpacity: Double? = try tagParams.optional(key: "cssOpacity")
                let cssBorderRadius: Double? = try tagParams.optional(key: "cssBorderRadius")
                let cssBorderWidth: Double? = try tagParams.optional(key: "cssBorderWidth")

                let gextTag = GExtTag(
                    tagId: tagIdString,
                    tagType: tagType,
                    text: text,
                    imgBase64: imgBase64,
                    cssBackgroundColor: cssBackgroundColor,
                    cssColor: cssColor,
                    cssOpacity: cssOpacity,
                    cssBorderWidth: cssBorderWidth,
                    cssBorderRadius: cssBorderRadius,
                    cssBorderColor: cssBorderColor,
                    cssBorderStyle: cssBorderStyle
                )
                result.append(gextTag)
            } catch {
                // Skip invalid entries and continue
                continue
            }
        }
        return result
    }

    private static func parseGExtRobot(params: ParamParser) throws -> GExtRobot? {
        guard let robotDict: [String: Any] = try params.optional(key: "gextRobot") else {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: robotDict)
            return try JSONDecoder().decode(GExtRobot.self, from: data)
        } catch {
            owsFailDebug("Failed to decode gextRobot: \(error)")
            return nil
        }
    }

    /// Parse a boolean capability with the given key from the given parser.
    /// - Important
    /// If the capability is missing (or weirdly fails to parse), we assume it
    /// was removed from the service and is therefore default-true.
    private static func parseCapabilityFlag(
        capabilitiesParser: ParamParser,
        capabilityKey: String,
    ) -> Bool {
        if capabilityKey == Capabilities.dummyCapabilityKey {
            return false
        }

        do {
            guard let capabilityFlag: Bool = try capabilitiesParser.optional(key: capabilityKey) else {
                owsFailDebug("Missing capability \(capabilityKey)! Assuming retired from service, and therefore hardcoded-on.")
                return true
            }

            return capabilityFlag
        } catch {
            owsFailDebug("Failed to parse capability \(capabilityKey)! Hardcoding to true.")
            return true
        }
    }
}
