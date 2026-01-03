import Foundation
import SwiftData

/// Represents an achievement linked to career goals
@Model
final class SDAchievement {
    @Attribute(.unique) var id: UUID
    var title: String
    var achievementDescription: String
    var dateAchieved: Date
    var impactStatement: String
    var goals: [SDCareerGoal] = []
    var evidenceLinks: [String]
    var tags: [String]
    var visibilityRaw: String
    var meeting: SDMeeting?
    var createdAt: Date

    // MARK: - Enum Computed Properties

    var visibility: Visibility {
        get { Visibility(rawValue: visibilityRaw) ?? .privateOnly }
        set { visibilityRaw = newValue.rawValue }
    }

    // MARK: - URL Computed Properties

    var evidenceLinkURLs: [URL] {
        get { evidenceLinks.compactMap { URL(string: $0) } }
        set { evidenceLinks = newValue.map { $0.absoluteString } }
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        dateAchieved.formatted(date: .abbreviated, time: .omitted)
    }

    var hasEvidence: Bool {
        !evidenceLinks.isEmpty
    }

    var isLinkedToGoals: Bool {
        !goals.isEmpty
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        achievementDescription: String = "",
        dateAchieved: Date = Date(),
        impactStatement: String = "",
        goals: [SDCareerGoal] = [],
        evidenceLinks: [URL] = [],
        tags: [String] = [],
        visibility: Visibility = .privateOnly,
        meeting: SDMeeting? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.dateAchieved = dateAchieved
        self.impactStatement = impactStatement
        self.goals = goals
        self.evidenceLinks = evidenceLinks.map { $0.absoluteString }
        self.tags = tags
        self.visibilityRaw = visibility.rawValue
        self.meeting = meeting
        self.createdAt = createdAt
    }

    /// Convert to Achievement struct for view compatibility
    func toAchievement() -> Achievement {
        Achievement(
            id: id,
            title: title,
            achievementDescription: achievementDescription,
            dateAchieved: dateAchieved,
            impactStatement: impactStatement,
            goalIDs: goals.map { $0.id },
            evidenceLinks: evidenceLinkURLs,
            tags: tags,
            visibility: visibility,
            meetingID: meeting?.id,
            createdAt: createdAt
        )
    }

    /// Update from Achievement struct
    func update(from achievement: Achievement) {
        title = achievement.title
        achievementDescription = achievement.achievementDescription
        dateAchieved = achievement.dateAchieved
        impactStatement = achievement.impactStatement
        evidenceLinkURLs = achievement.evidenceLinks
        tags = achievement.tags
        visibility = achievement.visibility
    }
}
