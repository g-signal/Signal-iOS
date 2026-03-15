//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
public import GRDB

/// 用户 ExtTag 数据库记录，对应 g_user_ext_tag 表
struct GUserExtTagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "g_user_ext_tag"

    enum Columns: String, ColumnExpression {
        case _id = "_id"
        case recipient_id = "recipient_id"
        case ext_tags = "ext_tags"
        case last_updated = "last_updated"
    }

    var _id: Int64?
    var recipient_id: Int64?
    var ext_tags: Data  // JSON编码的[ExtTag]数组
    var last_updated: Int64  // Unix时间戳(毫秒)

    mutating func didInsert(_ inserted: InsertionSuccess) {
        _id = inserted.rowID
    }

    static func from(extTags: [ExtTag], recipientId: Int64) throws -> GUserExtTagRecord {
        let extTagsData = try JSONEncoder().encode(extTags)
        let now = Date().ows_millisecondsSince1970

        return GUserExtTagRecord(
            _id: nil,
            recipient_id: recipientId,
            ext_tags: extTagsData,
            last_updated: Int64(now)
        )
    }

    func getExtTags() throws -> [ExtTag] {
        return try JSONDecoder().decode([ExtTag].self, from: ext_tags)
    }
}

/// 群组 ExtTag 数据库记录，对应 g_group_ext_tag 表
struct GGroupExtTagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "g_group_ext_tag"

    enum Columns: String, ColumnExpression {
        case _id = "_id"
        case group_id = "group_id"
        case ext_tags = "ext_tags"
        case last_updated = "last_updated"
    }

    var _id: Int64?
    var group_id: Int64?
    var ext_tags: Data  // JSON编码的[ExtTag]数组
    var last_updated: Int64  // Unix时间戳(毫秒)

    mutating func didInsert(_ inserted: InsertionSuccess) {
        _id = inserted.rowID
    }

    static func from(extTags: [ExtTag], groupId: Int64) throws -> GGroupExtTagRecord {
        let extTagsData = try JSONEncoder().encode(extTags)
        let now = Date().ows_millisecondsSince1970

        return GGroupExtTagRecord(
            _id: nil,
            group_id: groupId,
            ext_tags: extTagsData,
            last_updated: Int64(now)
        )
    }

    func getExtTags() throws -> [ExtTag] {
        return try JSONDecoder().decode([ExtTag].self, from: ext_tags)
    }
}