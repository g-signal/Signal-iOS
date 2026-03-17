//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

/// GExtTag 本地数据服务
public class GExtTagService: NSObject {

    public static let shared = GExtTagService()

    private override init() {
        super.init()
    }

    // MARK: - 用户 ExtTag 读取

    /// 从本地数据库获取用户的 GExtTag 数据
    public func fetchUserExtTags(
        for address: SignalServiceAddress,
        completion: @escaping (Result<[GExtTag], Error>) -> Void
    ) {
        do {
            let extTags = databaseStorage.read { transaction in
                return GExtTagStore.shared.getUserExtTags(for: address, transaction: transaction)
            }
            DispatchQueue.main.async {
                completion(.success(extTags))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(GExtTagError.parseError(error)))
            }
        }
    }

    /// 同步获取用户的 GExtTag 数据
    public func getUserExtTags(for address: SignalServiceAddress) -> [GExtTag] {
        return databaseStorage.read { transaction in
            return GExtTagStore.shared.getUserExtTags(for: address, transaction: transaction)
        }
    }

    // MARK: - 通知机制

    /// 发送 GExtTag 更新通知
    internal func postExtTagUpdateNotification(for address: SignalServiceAddress) {
        NotificationCenter.default.post(
            name: .gExtTagsDidUpdate,
            object: address,
            userInfo: nil
        )
    }
}

// MARK: - 错误类型

public enum GExtTagError: Error {
    case invalidAddress
    case parseError(Error)
}

// MARK: - 通知名称

public extension Notification.Name {
    static let gExtTagsDidUpdate = Notification.Name("gExtTagsDidUpdate")
}

// MARK: - 依赖注入

private extension GExtTagService {
    var databaseStorage: SDSDatabaseStorage {
        SSKEnvironment.shared.databaseStorageRef
    }
}