import Foundation
import CloudKit

/// Represents a person the user has 1:1 meetings with (manager, report, mentor, peer, etc.)
struct Manager: CloudKitRecordable, Codable {
    static let recordType = "Manager"

    let id: UUID
    var name: String
    var email: String?
    var relationshipType: String  // "My Manager", "Direct Report", "Mentor", "Peer", etc.
    var tags: [String]  // Optional additional tags for filtering
    let createdAt: Date

    // MARK: - Computed Properties

    /// Check if this person is the user's manager (drives IC mode)
    var isMyManager: Bool { relationshipType == "My Manager" }

    /// Check if this person is the user's direct report (drives Manager mode)
    var isDirectReport: Bool { relationshipType == "Direct Report" }

    /// Check if this person is neither manager nor report (mentor, peer, etc.)
    var isOtherRelationship: Bool { !isMyManager && !isDirectReport }

    /// Display title based on relationship type
    var roleTitle: String {
        if isMyManager { return "Manager" }
        if isDirectReport { return "Report" }
        return relationshipType
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        relationshipType: String = "My Manager",
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.relationshipType = relationshipType
        self.tags = tags
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

        // Handle migration from old enum-based field to new string-based field
        if let newRelationshipType = record.string(for: "relationshipType") {
            self.relationshipType = newRelationshipType
        } else if let oldRelationship = record.string(for: "relationship") {
            // Migrate from old enum values
            switch oldRelationship {
            case "myManager": self.relationshipType = "My Manager"
            case "directReport": self.relationshipType = "Direct Report"
            default: self.relationshipType = oldRelationship
            }
        } else {
            self.relationshipType = "My Manager"  // Default fallback
        }

        // Parse tags array
        if let tagsData = record["tags"] as? Data,
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            self.tags = decodedTags
        } else if let tagsArray = record["tags"] as? [String] {
            self.tags = tagsArray
        } else {
            self.tags = []
        }

        self.createdAt = createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["name"] = name
        record["email"] = email
        record["relationshipType"] = relationshipType
        // Also write to old field for backwards compatibility with older app versions
        if isMyManager {
            record["relationship"] = "myManager"
        } else if isDirectReport {
            record["relationship"] = "directReport"
        }
        // Store tags as JSON data for complex array storage
        if let tagsData = try? JSONEncoder().encode(tags) {
            record["tags"] = tagsData
        }
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
