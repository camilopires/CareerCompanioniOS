import Foundation
import CloudKit

/// Represents a 1:1 meeting with a manager
struct Meeting: CloudKitRecordable, Codable {
    static let recordType = "Meeting"

    let id: UUID
    var managerID: UUID
    var date: Date
    var status: MeetingStatus
    var notes: String
    var wentWell: [String]
    var didntGoWell: [String]
    var blockers: [String]
    var escalations: [String]
    var weekSentiment: Int?
    var meetingSentiment: Int?
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    var isUpcoming: Bool {
        status == .scheduled && date > Date()
    }

    var isPast: Bool {
        status == .completed || date < Date()
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    var weekSentimentValue: Sentiment? {
        weekSentiment.flatMap { Sentiment(rawValue: $0) }
    }

    var meetingSentimentValue: Sentiment? {
        meetingSentiment.flatMap { Sentiment(rawValue: $0) }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        managerID: UUID,
        date: Date,
        status: MeetingStatus = .scheduled,
        notes: String = "",
        wentWell: [String] = [],
        didntGoWell: [String] = [],
        blockers: [String] = [],
        escalations: [String] = [],
        weekSentiment: Int? = nil,
        meetingSentiment: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.managerID = managerID
        self.date = date
        self.status = status
        self.notes = notes
        self.wentWell = wentWell
        self.didntGoWell = didntGoWell
        self.blockers = blockers
        self.escalations = escalations
        self.weekSentiment = weekSentiment
        self.meetingSentiment = meetingSentiment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let managerRef = record.reference(for: "managerRef"),
              let managerIDString = managerRef.recordID.recordName.components(separatedBy: ":").last,
              let managerID = UUID(uuidString: managerIDString.isEmpty ? managerRef.recordID.recordName : managerIDString),
              let date = record.date(for: "date"),
              let statusString = record.string(for: "status"),
              let status = MeetingStatus(rawValue: statusString),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.managerID = managerID
        self.date = date
        self.status = status
        self.notes = record.stringOrEmpty(for: "notes")
        self.wentWell = record.stringArray(for: "wentWell")
        self.didntGoWell = record.stringArray(for: "didntGoWell")
        self.blockers = record.stringArray(for: "blockers")
        self.escalations = record.stringArray(for: "escalations")

        let weekSentimentInt = record.integer(for: "weekSentiment")
        self.weekSentiment = weekSentimentInt > 0 ? weekSentimentInt : nil

        let meetingSentimentInt = record.integer(for: "meetingSentiment")
        self.meetingSentiment = meetingSentimentInt > 0 ? meetingSentimentInt : nil

        self.createdAt = createdAt
        self.updatedAt = record.date(for: "updatedAt") ?? createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        let managerRecordID = CKRecord.ID(recordName: managerID.uuidString)
        record["managerRef"] = CKRecord.Reference(recordID: managerRecordID, action: .none)
        record["date"] = date
        record["status"] = status.rawValue
        record["notes"] = notes
        record.setStringArray(wentWell, for: "wentWell")
        record.setStringArray(didntGoWell, for: "didntGoWell")
        record.setStringArray(blockers, for: "blockers")
        record.setStringArray(escalations, for: "escalations")
        record["weekSentiment"] = weekSentiment ?? 0
        record["meetingSentiment"] = meetingSentiment ?? 0
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension Meeting {
    static let sample = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 7), // Next week
        status: .scheduled
    )

    static let sampleCompleted = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(-86400 * 7), // Last week
        status: .completed,
        notes: "Great discussion about project progress",
        wentWell: ["Completed the API integration", "Got positive feedback from stakeholders"],
        didntGoWell: ["Missed the documentation deadline"],
        blockers: ["Waiting for design assets"],
        escalations: ["Need additional budget for cloud resources"],
        weekSentiment: 4,
        meetingSentiment: 5
    )
}
