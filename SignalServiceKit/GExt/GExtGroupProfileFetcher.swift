//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

/// 负责从服务器获取群组 ExtTag 并存储到本地数据库
public actor GExtGroupProfileFetcher {

    public static let shared = GExtGroupProfileFetcher()

    // 正在进行中的请求，避免同一群组并发重复请求
    private var inFlightRequests = Set<String>()

    private init() {}

    // 最大允许的 imgBase64 字节数，与 GExtTagStore.maxImgBase64Length 保持一致
    private static let maxImgBase64Length = GExtTagStore.maxImgBase64Length

    // MARK: - 获取并存储群组 ExtTag

    /// 从服务器获取群组 ExtTag，并根据响应决定是否更新数据库
    ///
    /// - nil 响应：保持原有数据不变
    /// - 空数组：清空数据库中该群组的标签
    /// - 非空数组：更新数据库中该群组的标签
    public func fetchAndStoreGroupExtTags(groupId: String, groupIdData: Data) async {
        // 去重：同一群组已有请求在途则跳过
        guard !inFlightRequests.contains(groupId) else { return }
        inFlightRequests.insert(groupId)
        defer { inFlightRequests.remove(groupId) }

        do {
            guard let extTags = try await fetchGroupExtTags(groupId: groupId) else {
                return
            }

            let db = databaseStorage
            await db.awaitableWrite(file: #file, function: #function, line: #line) { tx in
                GExtTagStore.shared.setGroupExtTags(extTags, for: groupId, transaction: tx)
                if let thread = TSGroupThread.fetch(groupId: groupIdData, transaction: tx) {
                    db.touch(thread: thread, shouldReindex: false, shouldUpdateChatListUi: true, tx: tx)
                }
            }

            Logger.info("Stored \(extTags.count) ExtTags for group: \(groupId)")
        } catch {
            Logger.warn("Failed to fetch group ext tags for \(groupId): \(error)")
        }
    }

    // MARK: - 网络请求

    private func fetchGroupExtTags(groupId: String) async throws -> [GExtTag]? {
        let request = OWSRequestFactory.getGroupExtTagsRequest(groupId: groupId)
        let response = try await SSKEnvironment.shared.networkManagerRef.asyncRequest(
            request
        )

        guard let json = response.responseBodyJson as? [String: Any] else {
            return nil
        }

        return parseGroupExtTags(from: json)
    }

    // MARK: - 解析响应

    private func parseGroupExtTags(from json: [String: Any]) -> [GExtTag]? {
        guard let gextTagsArray = json["gextTags"] as? [[String: Any]] else {
            return nil
        }

        var result: [GExtTag] = []
        for tagDict in gextTagsArray {
            guard
                let tagId = tagDict["tagId"] as? String,
                let tagType = tagDict["tagType"] as? Int
            else {
                continue
            }

            let tag = GExtTag(
                tagId: tagId,
                tagType: tagType,
                text: tagDict["text"] as? String,
                imgBase64: {
                    guard let img = tagDict["imgBase64"] as? String else { return nil }
                    guard img.utf8.count <= Self.maxImgBase64Length else {
                        Logger.warn("imgBase64 too large (\(img.utf8.count) bytes), skipping for tag \(tagId)")
                        return nil
                    }
                    return img
                }(),
                cssBackgroundColor: tagDict["cssBackgroundColor"] as? String,
                cssColor: tagDict["cssColor"] as? String,
                cssOpacity: tagDict["cssOpacity"] as? Double,
                cssBorderWidth: tagDict["cssBorderWidth"] as? Double,
                cssBorderRadius: tagDict["cssBorderRadius"] as? Double,
                cssBorderColor: tagDict["cssBorderColor"] as? String,
                cssBorderStyle: tagDict["cssBorderStyle"] as? String
            )
            result.append(tag)
        }

        return result
    }

    // MARK: - 依赖

    private nonisolated var databaseStorage: SDSDatabaseStorage {
        SSKEnvironment.shared.databaseStorageRef
    }
}
