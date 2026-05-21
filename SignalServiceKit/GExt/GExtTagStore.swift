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

    // 与 GExtGroupProfileFetcher 保持一致
    static let maxImgBase64Length = 350_000

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

            let tags = try record.getExtTags()
            return tags
        } catch {
            owsFailDebug("Failed to fetch user ext tags: \(error)")
            return []
        }
    }

    /// 获取用户的机器人配置
    public func getUserRobot(
        for address: SignalServiceAddress,
        transaction: DBReadTransaction
    ) -> GExtRobot? {
        do {
            let aciString = try getAciString(for: address)

            guard let robotData = transaction.database.strictRead({ database in
                try GRecipientGExtTagRecord
                    .filter(GRecipientGExtTagRecord.Columns.aci == aciString)
                    .fetchOne(database)
            })?.robot else {
                return nil
            }

            return try JSONDecoder().decode(GExtRobot.self, from: robotData)
        } catch {
            owsFailDebug("Failed to fetch user robot: \(error)")
            return nil
        }
    }

    /// 设置用户的 GExtTag（使用 profile ID），只更新 tags 列，不影响 robot 列
    public func setUserExtTags(
        _ extTags: [GExtTag],
        for address: SignalServiceAddress,
        profileId: Int64,
        transaction: DBWriteTransaction
    ) {
        do {
            let aciString = try getAciString(for: address)

            // 过滤超大 imgBase64，与群组路径保持一致
            let sanitized = extTags.map { tag -> GExtTag in
                guard let img = tag.imgBase64, img.utf8.count > GExtTagStore.maxImgBase64Length else {
                    return tag
                }
                Logger.warn("imgBase64 too large for user tag \(tag.tagId), dropping image")
                return GExtTag(
                    tagId: tag.tagId, tagType: tag.tagType, text: tag.text,
                    imgBase64: nil,
                    cssBackgroundColor: tag.cssBackgroundColor, cssColor: tag.cssColor,
                    cssOpacity: tag.cssOpacity, cssBorderWidth: tag.cssBorderWidth,
                    cssBorderRadius: tag.cssBorderRadius, cssBorderColor: tag.cssBorderColor,
                    cssBorderStyle: tag.cssBorderStyle
                )
            }

            // 删除同 aci 但不同 _id 的旧记录，避免 aci 唯一约束冲突
            try transaction.database.execute(sql: """
                DELETE FROM gext_recipient WHERE aci = ? AND _id != ?
            """, arguments: [aciString, profileId])

            let tagsData = try JSONEncoder().encode(sanitized)
            let now = Date().ows_millisecondsSince1970

            // 行不存在时插入（robot 为 NULL），行存在时只更新 tags 和 last_updated
            try transaction.database.execute(sql: """
                INSERT INTO gext_recipient (_id, aci, tags, last_updated)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(_id) DO UPDATE SET
                    tags = excluded.tags,
                    last_updated = excluded.last_updated
            """, arguments: [profileId, aciString, tagsData, Int64(now)])

            Logger.info("Successfully set \(sanitized.count) ExtTags for profile ID \(profileId), aci: \(aciString)")
        } catch {
            owsFailDebug("Failed to set user ext tags with profile ID: \(error)")
        }
    }

    /// 设置用户的机器人配置（使用 profile ID），只更新 robot 列，不影响 tags 列
    public func setUserRobot(
        _ robot: GExtRobot,
        for address: SignalServiceAddress,
        profileId: Int64,
        transaction: DBWriteTransaction
    ) {
        do {
            let aciString = try getAciString(for: address)
            let robotData = try JSONEncoder().encode(robot)
            let now = Date().ows_millisecondsSince1970

            // 删除同 aci 但不同 _id 的旧记录，避免 aci 唯一约束冲突
            try transaction.database.execute(sql: """
                DELETE FROM gext_recipient WHERE aci = ? AND _id != ?
            """, arguments: [aciString, profileId])

            // 行不存在时插入（tags 为空数组），行存在时只更新 robot 和 last_updated
            let emptyTagsData = try JSONEncoder().encode([GExtTag]())
            try transaction.database.execute(sql: """
                INSERT INTO gext_recipient (_id, aci, tags, last_updated, robot)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(_id) DO UPDATE SET
                    robot = excluded.robot,
                    last_updated = excluded.last_updated
            """, arguments: [profileId, aciString, emptyTagsData, Int64(now), robotData])

            Logger.info("Successfully set robot for profile ID \(profileId), aci: \(aciString)")
        } catch {
            owsFailDebug("Failed to set user robot with profile ID: \(error)")
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

    // MARK: - 群组标签管理

    /// 获取群组的所有 GExtTag
    public func getGroupExtTags(
        for groupId: String,
        transaction: DBReadTransaction
    ) -> [GExtTag] {
        do {
            let record = transaction.database.strictRead { database in
                try GGroupGExtTagRecord
                    .filter(GGroupGExtTagRecord.Columns.group_id == groupId)
                    .fetchOne(database)
            }

            guard let record = record else {
                return []
            }

            return try record.getExtTags()
        } catch {
            owsFailDebug("Failed to fetch group ext tags: \(error)")
            return []
        }
    }

    /// 设置群组的 GExtTag（UPSERT，原子操作）
    public func setGroupExtTags(
        _ extTags: [GExtTag],
        for groupId: String,
        transaction: DBWriteTransaction
    ) {
        do {
            let sanitized = extTags.map { tag -> GExtTag in
                guard let img = tag.imgBase64, img.utf8.count > GExtTagStore.maxImgBase64Length else {
                    return tag
                }
                Logger.warn("imgBase64 too large for group tag \(tag.tagId), dropping image")
                return GExtTag(
                    tagId: tag.tagId, tagType: tag.tagType, text: tag.text,
                    imgBase64: nil,
                    cssBackgroundColor: tag.cssBackgroundColor, cssColor: tag.cssColor,
                    cssOpacity: tag.cssOpacity, cssBorderWidth: tag.cssBorderWidth,
                    cssBorderRadius: tag.cssBorderRadius, cssBorderColor: tag.cssBorderColor,
                    cssBorderStyle: tag.cssBorderStyle
                )
            }

            let tagsData = try JSONEncoder().encode(sanitized)
            let now = Date().ows_millisecondsSince1970

            try transaction.database.execute(sql: """
                INSERT INTO gext_groups (group_id, tags, last_updated)
                VALUES (?, ?, ?)
                ON CONFLICT(group_id) DO UPDATE SET
                    tags = excluded.tags,
                    last_updated = excluded.last_updated
            """, arguments: [groupId, tagsData, Int64(now)])
        } catch {
            owsFailDebug("Failed to set group ext tags: \(error)")
        }
    }

    /// 删除群组的所有 GExtTag
    public func deleteGroupExtTags(
        for groupId: String,
        transaction: DBWriteTransaction
    ) {
        do {
            try GGroupGExtTagRecord
                .filter(GGroupGExtTagRecord.Columns.group_id == groupId)
                .deleteAll(transaction.database)
        } catch {
            owsFailDebug("Failed to delete group ext tags: \(error)")
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
