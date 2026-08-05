//
// Copyright 2026 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
public import GRDB

public struct AdminDeleteRecord: Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName: String = "AdminDelete"

    public let interactionId: Int64
    public let deleteAuthorId: SignalRecipient.RowId

    static func insertRecord(
        interactionId: Int64,
        deleteAuthorId: SignalRecipient.RowId,
        tx: DBWriteTransaction,
    ) throws(GRDB.DatabaseError) -> Self {
        do {
            return try AdminDeleteRecord.fetchOne(
                tx.database,
                sql: """
                INSERT INTO \(AdminDeleteRecord.databaseTableName) (
                    \(CodingKeys.interactionId.rawValue),
                    \(CodingKeys.deleteAuthorId.rawValue)
                ) VALUES (?, ?) RETURNING *
                """,
                arguments: [
                    interactionId,
                    deleteAuthorId,
                ],
            )!
        } catch {
            throw error.forceCastToDatabaseError()
        }
    }

    public enum CodingKeys: String, CodingKey {
        case interactionId
        case deleteAuthorId
    }

    enum Columns {
        static let interactionId = Column(CodingKeys.interactionId.rawValue)
        static let deleteAuthorId = Column(CodingKeys.deleteAuthorId.rawValue)
    }
}
