//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import GRDB

/// 群组 GExtTag 数据库记录，对应 gext_groups 表
struct GGroupGExtTagRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "gext_groups"

    enum Columns: String, ColumnExpression {
        case _id = "_id"
        case group_id = "group_id"
        case tags = "tags"
        case last_updated = "last_updated"
    }

    var _id: Int64?
    var group_id: String
    var tags: Data  // JSON编码的[GExtTag]数组
    var last_updated: Int64  // Unix时间戳(毫秒)

    mutating func didInsert(with rowID: Int64, for column: String?) {
        _id = rowID
    }

    func getExtTags() throws -> [GExtTag] {
        return try JSONDecoder().decode([GExtTag].self, from: tags)
    }
}
