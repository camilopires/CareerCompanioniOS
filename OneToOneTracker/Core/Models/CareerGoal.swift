import Foundation
import CloudKit

/// Represents a career goal for tracking professional development
struct CareerGoal: CloudKitRecordable, Codable {
    static let recordType = "CareerGoal"

    let id: UUID
    var title: String
    var goalDescription: String
    var category: GoalCategory
    var targetDate: Date?
    var status: GoalStatus
    var priority: GoalPriority
    var successMetrics: String
    var trackingMethod: String
    var progress: Int // 0-100
    var skills: [String]
    var notes: String
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    var progressPercentage: Double {
        Double(progress) / 100.0
    }

    var isActive: Bool {
        status == .inProgress || status == .notStarted
    }

    var isAchieved: Bool {
        status == .achieved
    }

    var formattedTargetDate: String? {
        guard let targetDate else { return nil }
        return targetDate.formatted(date: .abbreviated, time: .omitted)
    }

    var daysUntilTarget: Int? {
        guard let targetDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day
    }

    var isOverdue: Bool {
        guard let targetDate, status != .achieved else { return false }
        return targetDate < Date()
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String = "",
        category: GoalCategory = .other,
        targetDate: Date? = nil,
        status: GoalStatus = .notStarted,
        priority: GoalPriority = .primary,
        successMetrics: String = "",
        trackingMethod: String = "",
        progress: Int = 0,
        skills: [String] = [],
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.category = category
        self.targetDate = targetDate
        self.status = status
        self.priority = priority
        self.successMetrics = successMetrics
        self.trackingMethod = trackingMethod
        self.progress = min(100, max(0, progress))
        self.skills = skills
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - CloudKit

    init?(record: CKRecord) {
        guard let idString = record.recordID.recordName.components(separatedBy: ":").last,
              let id = UUID(uuidString: idString.isEmpty ? record.recordID.recordName : idString),
              let title = record.string(for: "title"),
              let categoryString = record.string(for: "category"),
              let category = GoalCategory(rawValue: categoryString),
              let statusString = record.string(for: "status"),
              let status = GoalStatus(rawValue: statusString),
              let priorityString = record.string(for: "priority"),
              let priority = GoalPriority(rawValue: priorityString),
              let createdAt = record.date(for: "createdAt") else {
            return nil
        }

        self.id = id
        self.title = title
        self.goalDescription = record.stringOrEmpty(for: "goalDescription")
        self.category = category
        self.targetDate = record.date(for: "targetDate")
        self.status = status
        self.priority = priority
        self.successMetrics = record.stringOrEmpty(for: "successMetrics")
        self.trackingMethod = record.stringOrEmpty(for: "trackingMethod")
        self.progress = record.integer(for: "progress")
        self.skills = record.stringArray(for: "skills")
        self.notes = record.stringOrEmpty(for: "notes")
        self.createdAt = createdAt
        self.updatedAt = record.date(for: "updatedAt") ?? createdAt
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["title"] = title
        record["goalDescription"] = goalDescription
        record["category"] = category.rawValue
        record["targetDate"] = targetDate
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["successMetrics"] = successMetrics
        record["trackingMethod"] = trackingMethod
        record["progress"] = progress
        record.setStringArray(skills, for: "skills")
        record["notes"] = notes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }

    // MARK: - Mutations

    mutating func updateProgress(_ newProgress: Int) {
        progress = min(100, max(0, newProgress))
        updatedAt = Date()

        if progress >= 100 && status != .achieved {
            status = .achieved
        }
    }

    mutating func markAchieved() {
        status = .achieved
        progress = 100
        updatedAt = Date()
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CareerGoal, rhs: CareerGoal) -> Bool {
        lhs.id == rhs.id
    }
}
