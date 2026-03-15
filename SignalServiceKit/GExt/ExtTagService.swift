//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SignalServiceKit

/// ExtTag 数据同步服务
public class ExtTagService: NSObject {

    public static let shared = ExtTagService()

    private override init() {
        super.init()
    }

    // MARK: - 群组 ExtTag 同步

    /// 从服务器获取群组的 ExtTag 数据
    public func fetchGroupExtTags(
        for thread: TSGroupThread,
        completion: @escaping (Result<[ExtTag], Error>) -> Void
    ) {
        guard let groupModel = thread.groupModel as? TSGroupModelV2 else {
            completion(.failure(ExtTagError.invalidGroupType))
            return
        }

        let groupIdHex = groupModel.groupId.hexadecimalString
        let request = OWSRequestFactory.groupExtTagRequest(groupId: groupIdHex)

        firstly(on: DispatchQueue.global()) {
            networkManager.makePromise(request: request)
        }.done(on: DispatchQueue.global()) { response in
            do {
                let profile = try JSONDecoder().decode(GroupExtTagProfile.self, from: response.responseBodyData)

                // 存储到本地数据库
                databaseStorage.write { transaction in
                    ExtTagStore.shared.setGroupExtTags(profile.extTags, for: thread, transaction: transaction)
                }

                DispatchQueue.main.async {
                    completion(.success(profile.extTags))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ExtTagError.parseError(error)))
                }
            }
        }.catch(on: DispatchQueue.main) { error in
            completion(.failure(ExtTagError.networkError(error)))
        }
    }

    /// 从服务器获取用户的 ExtTag 数据
    public func fetchUserExtTags(
        for address: SignalServiceAddress,
        completion: @escaping (Result<[ExtTag], Error>) -> Void
    ) {
        guard let serviceId = address.serviceId else {
            completion(.failure(ExtTagError.invalidAddress))
            return
        }

        let request = OWSRequestFactory.userExtTagRequest(serviceId: serviceId.serviceIdString)

        firstly(on: DispatchQueue.global()) {
            networkManager.makePromise(request: request)
        }.done(on: DispatchQueue.global()) { response in
            do {
                let profile = try JSONDecoder().decode(UserExtTagProfile.self, from: response.responseBodyData)

                // 存储到本地数据库
                databaseStorage.write { transaction in
                    ExtTagStore.shared.setUserExtTags(profile.extTags, for: address, transaction: transaction)
                }

                DispatchQueue.main.async {
                    completion(.success(profile.extTags))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ExtTagError.parseError(error)))
                }
            }
        }.catch(on: DispatchQueue.main) { error in
            completion(.failure(ExtTagError.networkError(error)))
        }
    }

    // MARK: - 批量同步

    /// 批量同步会话列表中的 ExtTag 数据
    public func syncExtTagsForVisibleThreads(
        threadViewModels: [ThreadViewModel],
        completion: @escaping () -> Void
    ) {
        let dispatchGroup = DispatchGroup()

        for threadViewModel in threadViewModels {
            let thread = threadViewModel.threadRecord

            if let groupThread = thread as? TSGroupThread {
                dispatchGroup.enter()
                fetchGroupExtTags(for: groupThread) { _ in
                    dispatchGroup.leave()
                }
            } else if let contactThread = thread as? TSContactThread {
                dispatchGroup.enter()
                fetchUserExtTags(for: contactThread.contactAddress) { _ in
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - 自动同步策略

    /// 检查并同步过期的 ExtTag 数据
    public func syncStaleExtTags() {
        databaseStorage.read { transaction in
            // 获取需要更新的群组（超过1小时未更新）
            let staleThreshold = Date().addingTimeInterval(-3600).ows_millisecondsSince1970

            // 这里可以根据实际需求实现具体的查询逻辑
            // 暂时跳过具体实现，因为需要更复杂的数据库查询
        }
    }

    // MARK: - 通知机制

    /// 发送 ExtTag 更新通知
    private func postExtTagUpdateNotification(for thread: TSThread) {
        NotificationCenter.default.post(
            name: .extTagsDidUpdate,
            object: thread,
            userInfo: nil
        )
    }
}

// MARK: - 错误类型

public enum ExtTagError: Error {
    case invalidGroupType
    case invalidAddress
    case networkError(Error)
    case parseError(Error)
}

// MARK: - 通知名称

public extension Notification.Name {
    static let extTagsDidUpdate = Notification.Name("extTagsDidUpdate")
}

// MARK: - 依赖注入

private extension ExtTagService {
    var networkManager: NetworkManager {
        DependenciesBridge.shared.networkManager
    }

    var databaseStorage: SDSDatabaseStorage {
        SSKEnvironment.shared.databaseStorageRef
    }
}