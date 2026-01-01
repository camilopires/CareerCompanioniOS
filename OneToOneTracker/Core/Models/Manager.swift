import Foundation
import CloudKit

/// Represents a manager that the user has 1:1 meetings with
struct Manager: CloudKitRecordable, Codable {
    static let recordType = "Manager"

    let id: UUID
    var name: String
    var email: String?
    let createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let name = record.string(for: "name"),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.name = name
        self.email = record.string(for: "email")
        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["name"] = name
        record["email"] = email
        record["createdAt"] = createdAt
        return record
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Manager, rhs: Manager) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension Manager {
    static let sample = Manager(
        name: "Sarah Johnson",
        email: "sarah.johnson@company.com"
    )

    static let samples = [
        Manager(name: "Sarah Johnson", email: "sarah.johnson@company.com"),
        Manager(name: "Michael Chen", email: "michael.chen@company.com")
    ]
}
