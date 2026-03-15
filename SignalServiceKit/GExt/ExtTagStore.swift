//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
public import GRDB

/// ExtTag 存储管理器，基于新的表结构设计
public class ExtTagStore: NSObject {

    public static let shared = ExtTagStore()

    private override init() {
        super.init()
    }

    // MARK: - 群组标签管理

    /// 获取群组的所有 ExtTag
    public func getGroupExtTags(
        for thread: TSGroupThread,
        transaction: SDSAnyReadTransaction
    ) -> [ExtTag] {
        guard let grdbRead = transaction.unwrapGrdbRead else {
            owsFailDebug("Expected GRDB transaction")
            return []
        }

        do {
            // 获取群组在数据库中的数字ID
            let groupId = try getGroupDatabaseId(for: thread, transaction: grdbRead)

            guard let record = try GGroupExtTagRecord
                .filter(GGroupExtTagRecord.Columns.group_id == groupId)
                .fetchOne(grdbRead.database) else {
                return []
            }

            return try record.getExtTags()
        } catch {
            owsFailDebug("Failed to fetch group ext tags: \(error)")
            return []
        }
    }

    /// 设置群组的 ExtTag
    public func setGroupExtTags(
        _ extTags: [ExtTag],
        for thread: TSGroupThread,
        transaction: SDSAnyWriteTransaction
    ) {
        guard let grdbWrite = transaction.unwrapGrdbWrite else {
            owsFailDebug("Expected GRDB write transaction")
            return
        }

        do {
            let groupId = try getGroupDatabaseId(for: thread, transaction: grdbWrite)
            let record = try GGroupExtTagRecord.from(extTags: extTags, groupId: groupId)

            // 使用 REPLACE INTO 语义（由于 UNIQUE 约束）
            try record.save(grdbWrite.database)
        } catch {
            owsFailDebug("Failed to set group ext tags: \(error)")
        }
    }

    // MARK: - 用户标签管理

    /// 获取用户的所有 ExtTag
    public func getUserExtTags(
        for address: SignalServiceAddress,
        transaction: SDSAnyReadTransaction
    ) -> [ExtTag] {
        guard let grdbRead = transaction.unwrapGrdbRead else {
            owsFailDebug("Expected GRDB transaction")
            return []
        }

        do {
            let recipientId = try getRecipientDatabaseId(for: address, transaction: grdbRead)

            guard let record = try GUserExtTagRecord
                .filter(GUserExtTagRecord.Columns.recipient_id == recipientId)
                .fetchOne(grdbRead.database) else {
                return []
            }

            return try record.getExtTags()
        } catch {
            owsFailDebug("Failed to fetch user ext tags: \(error)")
            return []
        }
    }

    /// 设置用户的 ExtTag
    public func setUserExtTags(
        _ extTags: [ExtTag],
        for address: SignalServiceAddress,
        transaction: SDSAnyWriteTransaction
    ) {
        guard let grdbWrite = transaction.unwrapGrdbWrite else {
            owsFailDebug("Expected GRDB write transaction")
            return
        }

        do {
            let recipientId = try getRecipientDatabaseId(for: address, transaction: grdbWrite)
            let record = try GUserExtTagRecord.from(extTags: extTags, recipientId: recipientId)

            try record.save(grdbWrite.database)
        } catch {
            owsFailDebug("Failed to set user ext tags: \(error)")
        }
    }

    // MARK: - 清理操作

    /// 删除群组的所有 ExtTag（退出群组时调用）
    public func deleteGroupExtTags(
        for thread: TSGroupThread,
        transaction: SDSAnyWriteTransaction
    ) {
        guard let grdbWrite = transaction.unwrapGrdbWrite else {
            owsFailDebug("Expected GRDB write transaction")
            return
        }

        do {
            let groupId = try getGroupDatabaseId(for: thread, transaction: grdbWrite)

            try GGroupExtTagRecord
                .filter(GGroupExtTagRecord.Columns.group_id == groupId)
                .deleteAll(grdbWrite.database)
        } catch {
            owsFailDebug("Failed to delete group ext tags: \(error)")
        }
    }

    /// 删除用户的所有 ExtTag
    public func deleteUserExtTags(
        for address: SignalServiceAddress,
        transaction: SDSAnyWriteTransaction
    ) {
        guard let grdbWrite = transaction.unwrapGrdbWrite else {
            owsFailDebug("Expected GRDB write transaction")
            return
        }

        do {
            let recipientId = try getRecipientDatabaseId(for: address, transaction: grdbWrite)

            try GUserExtTagRecord
                .filter(GUserExtTagRecord.Columns.recipient_id == recipientId)
                .deleteAll(grdbWrite.database)
        } catch {
            owsFailDebug("Failed to delete user ext tags: \(error)")
        }
    }

    // MARK: - 私有辅助方法

    /// 获取群组在数据库中的数字ID
    private func getGroupDatabaseId(for groupThread: TSGroupThread, transaction: any DatabaseReader) throws -> Int64 {
        // 使用 thread 表的数字ID作为群组ID
        guard let threadId = groupThread.grdbId?.int64Value else {
            throw OWSAssertionError("Missing group thread database ID")
        }
        return threadId
    }

    /// 获取用户在数据库中的数字ID
    private func getRecipientDatabaseId(for address: SignalServiceAddress, transaction: any DatabaseReader) throws -> Int64 {
        let recipientDatabaseTable = RecipientDatabaseTable(recipientFetcher: DependenciesBridge.shared.recipientFetcher)
        let recipient = recipientDatabaseTable.fetchRecipient(address: address, transaction: transaction)

        guard let recipientId = recipient?.id else {
            throw OWSAssertionError("Missing recipient database ID for address: \(address)")
        }

        return recipientId
    }
}