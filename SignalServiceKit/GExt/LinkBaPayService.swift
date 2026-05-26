//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

// MARK: - Models

public struct BaUserInfo {
    public let linkId: String
    public let optId: String
    public let memberId: String
    public let optName: String
    public let email: String?
    public let mobile: String?
    public let linkStatus: Int
    public let linkStatusName: String
    public let canRequestLink: Bool
    public let failReason: String?
    public let expireTime: String?
}

public struct LinkRequestResult {
    public let linkId: String
    public let optId: String
    public let memberId: String
    public let baxsAppUserId: String
    public let linkStatus: Int
    public let linkStatusName: String
    public let expireTime: String?
}

public struct LinkResult {
    public let linkId: String
    public let optId: String
    public let memberId: String
    public let baxsAppUserId: String
    public let linkStatus: Int
    public let linkStatusName: String
    public let confirmTime: String?
    public let failReason: String?
}

public struct LinkedBaUserInfo {
    public let baxsAppUserId: String
    public let linkbaxsOptId: String?
    public let linkbaxsMemberId: String?
    public let linkbaxsOptName: String?
    public let linkbaxsOptEmail: String?
    public let linkbaxsOptMobile: String?
    public let linkbaxsDate: String?

    public var isLinked: Bool { linkbaxsOptId != nil }
}

// MARK: - LinkStatus

public enum LinkStatus: Int {
    case pendingScan = 1
    case scanned = 2
    case linked = 3
    case failed = 4
    case timeout = 5
    case requested = 6

    public var isTerminal: Bool {
        switch self {
        case .linked, .failed, .timeout: return true
        default: return false
        }
    }
}

// MARK: - Service

public class LinkBaPayService {

    public static let shared = LinkBaPayService()
    private init() {}

    private var networkManager: NetworkManager { SSKEnvironment.shared.networkManagerRef }

    // MARK: API 1: getBaUserInfo

    public func getBaUserInfo(linkId: String) async throws -> BaUserInfo {
        let request = OWSRequestFactory.linkBaPayGetBaUserInfoRequest(linkId: linkId)
        let response = try await networkManager.asyncRequest(request, canUseWebSocket: false)
        guard let json = response.responseBodyJson as? [String: Any] else {
            throw OWSGenericError("Invalid response from getBaUserInfo")
        }
        return try parseBaUserInfo(json)
    }

    // MARK: API 2: requestLink

    public func requestLink(linkId: String, userName: String, confirmResult: Bool) async throws -> LinkRequestResult {
        let request = OWSRequestFactory.linkBaPayRequestLinkRequest(linkId: linkId, userName: userName, confirmResult: confirmResult)
        let response = try await networkManager.asyncRequest(request, canUseWebSocket: false)
        guard let json = response.responseBodyJson as? [String: Any] else {
            throw OWSGenericError("Invalid response from requestLink")
        }
        return try parseLinkRequestResult(json)
    }

    // MARK: API 3: getLinkResult

    public func getLinkResult(linkId: String) async throws -> LinkResult {
        let request = OWSRequestFactory.linkBaPayGetLinkResultRequest(linkId: linkId)
        let response = try await networkManager.asyncRequest(request, canUseWebSocket: false)
        guard let json = response.responseBodyJson as? [String: Any] else {
            throw OWSGenericError("Invalid response from getLinkResult")
        }
        return try parseLinkResult(json)
    }

    // MARK: API 4: getLinkedBaUserInfo

    public func getLinkedBaUserInfo() async throws -> LinkedBaUserInfo {
        let request = OWSRequestFactory.linkBaPayGetLinkedBaUserInfoRequest()
        let response = try await networkManager.asyncRequest(request, canUseWebSocket: false)
        guard let json = response.responseBodyJson as? [String: Any] else {
            throw OWSGenericError("Invalid response from getLinkedBaUserInfo")
        }
        return parseLinkedBaUserInfo(json)
    }

    // MARK: - Parsing

    private func parseBaUserInfo(_ json: [String: Any]) throws -> BaUserInfo {
        guard
            let linkId = json["linkId"] as? String,
            let optId = json["optId"] as? String,
            let memberId = json["memberId"] as? String,
            let optName = json["optName"] as? String,
            let linkStatus = json["linkStatus"] as? Int,
            let linkStatusName = json["linkStatusName"] as? String,
            let canRequestLink = json["canRequestLink"] as? Bool
        else {
            throw OWSGenericError("Missing required fields in getBaUserInfo response")
        }
        return BaUserInfo(
            linkId: linkId,
            optId: optId,
            memberId: memberId,
            optName: optName,
            email: json["email"] as? String,
            mobile: json["mobile"] as? String,
            linkStatus: linkStatus,
            linkStatusName: linkStatusName,
            canRequestLink: canRequestLink,
            failReason: json["failReason"] as? String,
            expireTime: json["expireTime"] as? String
        )
    }

    private func parseLinkRequestResult(_ json: [String: Any]) throws -> LinkRequestResult {
        guard
            let linkId = json["linkId"] as? String,
            let optId = json["optId"] as? String,
            let memberId = json["memberId"] as? String,
            let baxsAppUserId = json["baxsAppUserId"] as? String,
            let linkStatus = json["linkStatus"] as? Int,
            let linkStatusName = json["linkStatusName"] as? String
        else {
            throw OWSGenericError("Missing required fields in requestLink response")
        }
        return LinkRequestResult(
            linkId: linkId,
            optId: optId,
            memberId: memberId,
            baxsAppUserId: baxsAppUserId,
            linkStatus: linkStatus,
            linkStatusName: linkStatusName,
            expireTime: json["expireTime"] as? String
        )
    }

    private func parseLinkResult(_ json: [String: Any]) throws -> LinkResult {
        guard
            let linkId = json["linkId"] as? String,
            let optId = json["optId"] as? String,
            let memberId = json["memberId"] as? String,
            let baxsAppUserId = json["baxsAppUserId"] as? String,
            let linkStatus = json["linkStatus"] as? Int,
            let linkStatusName = json["linkStatusName"] as? String
        else {
            throw OWSGenericError("Missing required fields in getLinkResult response")
        }
        return LinkResult(
            linkId: linkId,
            optId: optId,
            memberId: memberId,
            baxsAppUserId: baxsAppUserId,
            linkStatus: linkStatus,
            linkStatusName: linkStatusName,
            confirmTime: json["confirmTime"] as? String,
            failReason: json["failReason"] as? String
        )
    }

    private func parseLinkedBaUserInfo(_ json: [String: Any]) -> LinkedBaUserInfo {
        return LinkedBaUserInfo(
            baxsAppUserId: json["baxsAppUserId"] as? String ?? "",
            linkbaxsOptId: json["linkbaxsOptId"] as? String,
            linkbaxsMemberId: json["linkbaxsMemberId"] as? String,
            linkbaxsOptName: json["linkbaxsOptName"] as? String,
            linkbaxsOptEmail: json["linkbaxsOptEmail"] as? String,
            linkbaxsOptMobile: json["linkbaxsOptMobile"] as? String,
            linkbaxsDate: json["linkbaxsDate"] as? String
        )
    }
}
