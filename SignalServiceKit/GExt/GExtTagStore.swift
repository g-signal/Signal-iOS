//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import GRDB
public import LibSignalClient

/// GExtTag 存储管理器，基于新的表结构设计
public class GExtTagStore: NSObject {

    public static let shared = GExtTagStore()

    private override init() {
        super.init()
    }

    // MARK: - 用户标签管理

    /// 获取用户的所有 GExtTag
    public func getUserExtTags(
        for address: SignalServiceAddress,
        transaction: DBReadTransaction
    ) -> [GExtTag] {
        do {
            let aciString = try getAciString(for: address)

            let record = transaction.database.strictRead { database in
                try GRecipientGExtTagRecord
                    .filter(GRecipientGExtTagRecord.Columns.aci == aciString)
                    .fetchOne(database)
            }

            guard let record = record else {
                return []
            }

            return try record.getExtTags()
        } catch {
            owsFailDebug("Failed to fetch user ext tags: \(error)")
            return []
        }
    }

    /// 设置用户的 GExtTag
    public func setUserExtTags(
        _ extTags: [GExtTag],
        for address: SignalServiceAddress,
        transaction: DBWriteTransaction
    ) {
        do {
            let aciString = try getAciString(for: address)
            let record = try GRecipientGExtTagRecord.from(extTags: extTags, aci: aciString)

            try record.save(transaction.database)
        } catch {
            owsFailDebug("Failed to set user ext tags: \(error)")
        }
    }

    /// 设置用户的 GExtTag（使用 profile ID）
    public func setUserExtTags(
        _ extTags: [GExtTag],
        for address: SignalServiceAddress,
        profileId: Int64,
        transaction: DBWriteTransaction
    ) {
        do {
            let aciString = try getAciString(for: address)

            // 首先删除现有记录（按 aci 删除，因为这是业务主键）
            try GRecipientGExtTagRecord
                .filter(GRecipientGExtTagRecord.Columns.aci == aciString)
                .deleteAll(transaction.database)

            // 插入新记录，使用 profile ID 作为主键
            let tagsData = try JSONEncoder().encode(extTags)
            let now = Date().ows_millisecondsSince1970

            try transaction.database.execute(sql: """
                INSERT INTO gext_recipient (_id, aci, tags, last_updated)
                VALUES (?, ?, ?, ?)
            """, arguments: [profileId, aciString, tagsData, Int64(now)])

            Logger.info("Successfully set \(extTags.count) ExtTags for profile ID \(profileId), aci: \(aciString)")
        } catch {
            owsFailDebug("Failed to set user ext tags with profile ID: \(error)")
        }
    }

    /// 删除用户的所有 GExtTag（使用 profile ID）
    public func deleteUserExtTags(
        profileId: Int64,
        transaction: DBWriteTransaction
    ) {
        do {
            try GRecipientGExtTagRecord
                .filter(GRecipientGExtTagRecord.Columns._id == profileId)
                .deleteAll(transaction.database)
        } catch {
            owsFailDebug("Failed to delete user ext tags by profile ID: \(error)")
        }
    }

    /// 删除用户的所有 GExtTag
    public func deleteUserExtTags(
        for address: SignalServiceAddress,
        transaction: DBWriteTransaction
    ) {
        do {
            let aciString = try getAciString(for: address)

            try GRecipientGExtTagRecord
                .filter(GRecipientGExtTagRecord.Columns.aci == aciString)
                .deleteAll(transaction.database)
        } catch {
            owsFailDebug("Failed to delete user ext tags: \(error)")
        }
    }

    // MARK: - 私有辅助方法

    /// 获取用户ACI字符串
    private func getAciString(for address: SignalServiceAddress) throws -> String {
        guard let serviceId = address.serviceId else {
            throw OWSAssertionError("Missing service ID for address: \(address)")
        }
        return serviceId.serviceIdUppercaseString
    }
}
