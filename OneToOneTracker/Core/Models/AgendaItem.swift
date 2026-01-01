import Foundation
import CloudKit

/// Represents an item on the meeting agenda
struct AgendaItem: CloudKitRecordable, Codable {
    static let recordType = "AgendaItem"

    let id: UUID
    var meetingID: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var order: Int
    let createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        meetingID: UUID,
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.meetingID = meetingID
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.order = order
        self.createdAt = createdAt
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let meetingRef = record.reference(for: "meetingRef"),
              let meetingIDString = meetingRef.recordID.recordName.components(separatedBy: ":").last,
              let meetingID = UUID(uuidString: meetingIDString.isEmpty ? meetingRef.recordID.recordName : meetingIDString),
              let title = record.string(for: "title"),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.meetingID = meetingID
        self.title = title
        self.notes = record.stringOrEmpty(for: "notes")
        self.isCompleted = record.bool(for: "isCompleted")
        self.order = record.integer(for: "order")
        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        let meetingRecordID = CKRecord.ID(recordName: meetingID.uuidString)
        record["meetingRef"] = CKRecord.Reference(recordID: meetingRecordID, action: .deleteSelf)
        record["title"] = title
        record["notes"] = notes
        record.setBool(isCompleted, for: "isCompleted")
        record["order"] = order
        record["createdAt"] = createdAt
        return record
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AgendaItem, rhs: AgendaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension AgendaItem {
    static let samples: [AgendaItem] = {
        let meetingID = UUID()
        return [
            AgendaItem(meetingID: meetingID, title: "Review last week's action items", order: 0),
            AgendaItem(meetingID: meetingID, title: "Discuss project roadmap", order: 1),
            AgendaItem(meetingID: meetingID, title: "Career development update", order: 2),
            AgendaItem(meetingID: meetingID, title: "Team feedback", order: 3)
        ]
    }()
}
