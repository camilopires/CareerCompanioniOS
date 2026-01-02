import Foundation
import CloudKit

/// Represents an achievement linked to career goals
struct Achievement: CloudKitRecordable, Codable {
    static let recordType = "Achievement"

    let id: UUID
    var title: String
    var achievementDescription: String
    var dateAchieved: Date
    var impactStatement: String
    var goalIDs: [UUID]
    var evidenceLinks: [URL]
    var tags: [String]
    var visibility: Visibility
    var meetingID: UUID?
    let createdAt: Date

    // MARK: - Computed Properties

    var formattedDate: String {
        dateAchieved.formatted(date: .abbreviated, time: .omitted)
    }

    var hasEvidence: Bool {
        !evidenceLinks.isEmpty
    }

    var isLinkedToGoals: Bool {
        !goalIDs.isEmpty
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        achievementDescription: String = "",
        dateAchieved: Date = Date(),
        impactStatement: String = "",
        goalIDs: [UUID] = [],
        evidenceLinks: [URL] = [],
        tags: [String] = [],
        visibility: Visibility = .privateOnly,
        meetingID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.dateAchieved = dateAchieved
        self.impactStatement = impactStatement
        self.goalIDs = goalIDs
        self.evidenceLinks = evidenceLinks
        self.tags = tags
        self.visibility = visibility
        self.meetingID = meetingID
        self.createdAt = createdAt
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let title = record.string(for: "title"),
              let dateAchieved = record.date(for: "dateAchieved"),
              let visibilityString = record.string(for: "visibility"),
              let visibility = Visibility(rawValue: visibilityString),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.title = title
        self.achievementDescription = record.stringOrEmpty(for: "achievementDescription")
        self.dateAchieved = dateAchieved
        self.impactStatement = record.stringOrEmpty(for: "impactStatement")
        self.evidenceLinks = record.urlArray(for: "evidenceLinks")
        self.tags = record.stringArray(for: "tags")
        self.visibility = visibility
        self.createdAt = createdAt

        // Parse goal references
        let goalRefs = record.referenceArray(for: "goalRefs")
        self.goalIDs = goalRefs.compactMap { ref in
            let idString = ref.recordID.recordName.components(separatedBy: ":").last ?? ref.recordID.recordName
            return UUID(uuidString: idString)
        }

        // Parse optional meeting reference
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
        record["title"] = title
        record["achievementDescription"] = achievementDescription
        record["dateAchieved"] = dateAchieved
        record["impactStatement"] = impactStatement
        record.setURLArray(evidenceLinks, for: "evidenceLinks")
        record.setStringArray(tags, for: "tags")
        record["visibility"] = visibility.rawValue
        record["createdAt"] = createdAt

        // Set goal references
        let goalRefs = goalIDs.map { goalID in
            let recordID = CKRecord.ID(recordName: goalID.uuidString)
            return CKRecord.Reference(recordID: recordID, action: .none)
        }
        record["goalRefs"] = goalRefs

        // Set optional meeting reference
        if let meetingID {
            let meetingRecordID = CKRecord.ID(recordName: meetingID.uuidString)
            record["meetingRef"] = CKRecord.Reference(recordID: meetingRecordID, action: .none)
        }

        return record
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}
