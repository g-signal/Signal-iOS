//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import GRDB

/// 用户 GExtTag 数据库记录，对应 gext_recipient 表
struct GRecipientGExtTagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "gext_recipient"

    enum Columns: String, ColumnExpression {
        case _id = "_id"
        case aci = "aci"
        case tags = "tags"
        case last_updated = "last_updated"
    }

    var _id: Int64?
    var aci: String
    var tags: Data  // JSON编码的[GExtTag]数组
    var last_updated: Int64  // Unix时间戳(毫秒)

    mutating func didInsert(with rowID: Int64, for column: String?) {
        _id = rowID
    }

    static func from(extTags: [GExtTag], aci: String) throws -> GRecipientGExtTagRecord {
        let tagsData = try JSONEncoder().encode(extTags)
        let now = Date().ows_millisecondsSince1970

        return GRecipientGExtTagRecord(
            _id: nil,
            aci: aci,
            tags: tagsData,
            last_updated: Int64(now)
        )
    }

    static func from(extTags: [GExtTag], profileId: Int64, aci: String) throws -> GRecipientGExtTagRecord {
        let tagsData = try JSONEncoder().encode(extTags)
        let now = Date().ows_millisecondsSince1970

        return GRecipientGExtTagRecord(
            _id: profileId,
            aci: aci,
            tags: tagsData,
            last_updated: Int64(now)
        )
    }

    func getExtTags() throws -> [GExtTag] {
        return try JSONDecoder().decode([GExtTag].self, from: tags)
    }
}