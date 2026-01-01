import Foundation
import SwiftUI

// MARK: - Meeting Status

enum MeetingStatus: String, Codable, CaseIterable, Identifiable {
    case scheduled
    case inProgress
    case completed
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .inProgress: return Color(red: 0.255, green: 0.318, blue: 0.839)
        case .completed: return .green
        case .cancelled: return .secondary
        }
    }
}

// MARK: - Priority

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Action Item Status

enum ActionItemStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case inProgress
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .open: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .open: return .secondary
        case .inProgress: return Color(red: 0.255, green: 0.318, blue: 0.839)
        case .completed: return .green
        }
    }
}

// MARK: - Owner

enum Owner: String, Codable, CaseIterable, Identifiable {
    case me
    case manager

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .me: return "Me"
        case .manager: return "Manager"
        }
    }

    var icon: String {
        switch self {
        case .me: return "person.fill"
        case .manager: return "person.badge.shield.checkmark.fill"
        }
    }
}

// MARK: - Goal Category

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case technical
    case leadership
    case communication
    case domainKnowledge
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .technical: return "Technical"
        case .leadership: return "Leadership"
        case .communication: return "Communication"
        case .domainKnowledge: return "Domain Knowledge"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .technical: return "hammer.fill"
        case .leadership: return "person.3.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .domainKnowledge: return "book.fill"
        case .other: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .technical: return .blue
        case .leadership: return .purple
        case .communication: return .orange
        case .domainKnowledge: return .green
        case .other: return .gray
        }
    }
}

// MARK: - Goal Status

enum GoalStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case achieved
    case paused

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .achieved: return "Achieved"
        case .paused: return "Paused"
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .achieved: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .inProgress: return Color(red: 0.255, green: 0.318, blue: 0.839)
        case .achieved: return .green
        case .paused: return .orange
        }
    }
}

// MARK: - Goal Priority

enum GoalPriority: String, Codable, CaseIterable, Identifiable {
    case primary
    case secondary

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .secondary: return "Secondary"
        }
    }

    var icon: String {
        switch self {
        case .primary: return "star.fill"
        case .secondary: return "star"
        }
    }
}

// MARK: - Visibility

enum Visibility: String, Codable, CaseIterable, Identifiable {
    case privateOnly
    case manager
    case publicVisible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateOnly: return "Private"
        case .manager: return "Share with Manager"
        case .publicVisible: return "Public"
        }
    }

    var icon: String {
        switch self {
        case .privateOnly: return "lock.fill"
        case .manager: return "person.2.fill"
        case .publicVisible: return "globe"
        }
    }
}

// MARK: - Sentiment

enum Sentiment: Int, CaseIterable, Identifiable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .veryBad: return "😞"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }

    var displayName: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        }
    }

    var color: Color {
        switch self {
        case .veryBad: return .red
        case .bad: return .orange
        case .neutral: return .yellow
        case .good: return .mint
        case .veryGood: return .green
        }
    }

    var accessibilityLabel: String {
        "\(rawValue) out of 5: \(displayName)"
    }
}

// MARK: - Export Format

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case slack
    case teams
    case email
    case markdown
    case plainText
    case pdf

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slack: return "Slack"
        case .teams: return "Microsoft Teams"
        case .email: return "Email"
        case .markdown: return "Markdown"
        case .plainText: return "Plain Text"
        case .pdf: return "PDF"
        }
    }

    var icon: String {
        switch self {
        case .slack: return "number"
        case .teams: return "person.3.fill"
        case .email: return "envelope.fill"
        case .markdown: return "doc.text.fill"
        case .plainText: return "doc.plaintext.fill"
        case .pdf: return "doc.fill"
        }
    }
}

// MARK: - User Role (v2.0)

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case individualContributor = "ic"
    case manager = "manager"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .individualContributor: return "Individual Contributor"
        case .manager: return "Manager"
        }
    }

    var shortName: String {
        switch self {
        case .individualContributor: return "IC"
        case .manager: return "Mgr"
        }
    }

    var icon: String {
        switch self {
        case .individualContributor: return "person.fill"
        case .manager: return "person.3.fill"
        }
    }
}

// MARK: - Manager Relationship (v2.0)

enum ManagerRelationship: String, Codable, CaseIterable, Identifiable {
    case myManager
    case directReport

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .myManager: return "My Manager"
        case .directReport: return "Direct Report"
        }
    }

    var icon: String {
        switch self {
        case .myManager: return "person.badge.shield.checkmark.fill"
        case .directReport: return "person.fill"
        }
    }

    var description: String {
        switch self {
        case .myManager: return "I report to this person"
        case .directReport: return "This person reports to me"
        }
    }
}

// MARK: - Meeting Perspective (v2.0)

enum MeetingPerspective: String, Codable, CaseIterable, Identifiable {
    case asEmployee
    case asManager

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .asEmployee: return "With My Manager"
        case .asManager: return "With My Report"
        }
    }

    var icon: String {
        switch self {
        case .asEmployee: return "person.badge.shield.checkmark.fill"
        case .asManager: return "person.fill"
        }
    }
}
