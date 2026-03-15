//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public extension OWSRequestFactory {

    /// 构造获取群组 ExtTag 的 REST 请求
    /// 对应接口：GET /v1/gext/group/profile/{groupId}
    static func groupExtTagRequest(groupId: String) -> TSRequest {
        let path = "v1/gext/group/profile/\(groupId)"
        let request = TSRequest(url: URL(string: path)!)
        request.httpMethod = "GET"
        request.shouldHaveAuthorizationHeaders = true
        return request
    }

    /// 构造获取个人 ExtTag 的 REST 请求（预留）
    /// 对应接口：GET /v1/gext/user/profile/{serviceId}
    static func userExtTagRequest(serviceId: String) -> TSRequest {
        let path = "v1/gext/user/profile/\(serviceId)"
        let request = TSRequest(url: URL(string: path)!)
        request.httpMethod = "GET"
        request.shouldHaveAuthorizationHeaders = true
        return request
    }
}