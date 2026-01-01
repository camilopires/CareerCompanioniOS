import Foundation
import CloudKit

/// Represents a manager or direct report that the user has 1:1 meetings with
struct Manager: CloudKitRecordable, Codable {
    static let recordType = "Manager"

    let id: UUID
    var name: String
    var email: String?
    var relationship: ManagerRelationship
    let createdAt: Date

    // MARK: - Computed Properties

    /// Display title based on relationship
    var roleTitle: String {
        switch relationship {
        case .myManager: return "Manager"
        case .directReport: return "Report"
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        relationship: ManagerRelationship = .myManager,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.relationship = relationship
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

        // Parse relationship, defaulting to myManager for backwards compatibility
        if let relationshipString = record.string(for: "relationship"),
           let relationship = ManagerRelationship(rawValue: relationshipString) {
            self.relationship = relationship
        } else {
            self.relationship = .myManager
        }

        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["name"] = name
        record["email"] = email
        record["relationship"] = relationship.rawValue
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
