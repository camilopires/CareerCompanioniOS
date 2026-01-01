import Foundation
import CloudKit

/// Represents an action item from a 1:1 meeting or standalone task
struct ActionItem: CloudKitRecordable, Codable {
    static let recordType = "ActionItem"

    let id: UUID
    var meetingID: UUID?
    var title: String
    var itemDescription: String
    var dueDate: Date?
    var priority: Priority
    var status: ActionItemStatus
    var owner: Owner
    var links: [URL]
    let createdAt: Date
    var completedAt: Date?
    var completionNotes: String?

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let dueDate, status != .completed else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueThisWeek: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var formattedDueDate: String? {
        guard let dueDate else { return nil }

        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else {
            return dueDate.formatted(date: .abbreviated, time: .omitted)
        }
    }

    var isOpen: Bool {
        status != .completed
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        meetingID: UUID? = nil,
        title: String,
        itemDescription: String = "",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: ActionItemStatus = .open,
        owner: Owner = .me,
        links: [URL] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        completionNotes: String? = nil
    ) {
        self.id = id
        self.meetingID = meetingID
        self.title = title
        self.itemDescription = itemDescription
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.owner = owner
        self.links = links
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.completionNotes = completionNotes
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let title = record.string(for: "title"),
              let priorityString = record.string(for: "priority"),
              let priority = Priority(rawValue: priorityString),
              let statusString = record.string(for: "status"),
              let status = ActionItemStatus(rawValue: statusString),
              let ownerString = record.string(for: "owner"),
              let owner = Owner(rawValue: ownerString),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.title = title
        self.itemDescription = record.stringOrEmpty(for: "itemDescription")
        self.dueDate = record.date(for: "dueDate")
        self.priority = priority
        self.status = status
        self.owner = owner
        self.links = record.urlArray(for: "links")
        self.createdAt = createdAt
        self.completedAt = record.date(for: "completedAt")
        self.completionNotes = record.string(for: "completionNotes")

        if let meetingRef = record.reference(for: "meetingRef"),
           let meetingIDString = meetingRef.recordID.recordName.components(separatedBy: ":").last,
           let meetingID = UUID(uuidString: meetingIDString.isEmpty ? meetingRef.recordID.recordName : meetingIDString) {
            self.meetingID = meetingID
        } else {
            self.meetingID = nil
        }
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        if let meetingID {
            let meetingRecordID = CKRecord.ID(recordName: meetingID.uuidString)
            record["meetingRef"] = CKRecord.Reference(recordID: meetingRecordID, action: .none)
        }

        record["title"] = title
        record["itemDescription"] = itemDescription
        record["dueDate"] = dueDate
        record["priority"] = priority.rawValue
        record["status"] = status.rawValue
        record["owner"] = owner.rawValue
        record.setURLArray(links, for: "links")
        record["createdAt"] = createdAt
        record["completedAt"] = completedAt
        record["completionNotes"] = completionNotes
        return record
    }

    // MARK: - Mutations

    mutating func markComplete(notes: String? = nil) {
        status = .completed
        completedAt = Date()
        completionNotes = notes
    }

    mutating func reopen() {
        status = .open
        completedAt = nil
        completionNotes = nil
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension ActionItem {
    static let sample = ActionItem(
        title: "Review Q4 objectives",
        itemDescription: "Review and finalize the Q4 objectives document",
        dueDate: Date().addingTimeInterval(86400 * 3),
        priority: .high
    )

    static let samples: [ActionItem] = [
        ActionItem(
            title: "Review Q4 objectives",
            itemDescription: "Review and finalize the Q4 objectives document",
            dueDate: Date().addingTimeInterval(86400 * 3),
            priority: .high
        ),
        ActionItem(
            title: "Schedule team retrospective",
            dueDate: Date().addingTimeInterval(86400 * 7),
            priority: .medium
        ),
        ActionItem(
            title: "Update documentation",
            itemDescription: "Update the API documentation with new endpoints",
            dueDate: Date().addingTimeInterval(-86400), // Overdue
            priority: .low
        ),
        ActionItem(
            title: "Follow up on budget request",
            priority: .high,
            owner: .manager
        )
    ]
}
