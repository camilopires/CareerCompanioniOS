import Foundation
import SwiftData

/// Represents a career goal for tracking professional development
@Model
final class SDCareerGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var goalDescription: String
    var categoryRaw: String
    var targetDate: Date?
    var statusRaw: String
    var priorityRaw: String
    var successMetrics: String
    var trackingMethod: String
    var progress: Int
    var skills: [String]
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \SDAchievement.goals)
    var achievements: [SDAchievement] = []

    // MARK: - Enum Computed Properties

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var priority: GoalPriority {
        get { GoalPriority(rawValue: priorityRaw) ?? .primary }
        set { priorityRaw = newValue.rawValue }
    }

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
        self.categoryRaw = category.rawValue
        self.targetDate = targetDate
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.successMetrics = successMetrics
        self.trackingMethod = trackingMethod
        self.progress = min(100, max(0, progress))
        self.skills = skills
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Mutations

    func updateProgress(_ newProgress: Int) {
        progress = min(100, max(0, newProgress))
        updatedAt = Date()

        if progress >= 100 && status != .achieved {
            status = .achieved
        }
    }

    func markAchieved() {
        status = .achieved
        progress = 100
        updatedAt = Date()
    }

    /// Convert to CareerGoal struct for view compatibility
    func toCareerGoal() -> CareerGoal {
        CareerGoal(
            id: id,
            title: title,
            goalDescription: goalDescription,
            category: category,
            targetDate: targetDate,
            status: status,
            priority: priority,
            successMetrics: successMetrics,
            trackingMethod: trackingMethod,
            progress: progress,
            skills: skills,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Update from CareerGoal struct
    func update(from goal: CareerGoal) {
        title = goal.title
        goalDescription = goal.goalDescription
        category = goal.category
        targetDate = goal.targetDate
        status = goal.status
        priority = goal.priority
        successMetrics = goal.successMetrics
        trackingMethod = goal.trackingMethod
        progress = goal.progress
        skills = goal.skills
        notes = goal.notes
        updatedAt = goal.updatedAt
    }
}
