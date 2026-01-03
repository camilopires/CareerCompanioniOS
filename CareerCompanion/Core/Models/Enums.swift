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

// MARK: - Manager Relationship (DEPRECATED in v2.2)
// This enum is deprecated. Use Manager.relationshipType (String) instead.
// Relationship types are now user-defined strings stored in AppSettings.
// Special values: "My Manager" (drives IC mode), "Direct Report" (drives Manager mode)
// Kept for CloudKit migration compatibility only.

@available(*, deprecated, message: "Use Manager.relationshipType (String) instead")
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

// MARK: - Export Style (v2.8)

enum ExportStyle: String, Codable, CaseIterable, Identifiable {
    case professional
    case casual
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .minimal: return "Minimal"
        }
    }

    var description: String {
        switch self {
        case .professional: return "Clean headers, bullet points, formal"
        case .casual: return "Emojis, friendly formatting"
        case .minimal: return "Simple, no decorations"
        }
    }

    var icon: String {
        switch self {
        case .professional: return "briefcase.fill"
        case .casual: return "face.smiling.fill"
        case .minimal: return "text.alignleft"
        }
    }
}

// MARK: - Export Template (v2.8)

enum ExportTemplate: String, Codable, CaseIterable, Identifiable {
    case prep
    case summary

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .prep: return "Meeting Prep"
        case .summary: return "Meeting Summary"
        }
    }

    var description: String {
        switch self {
        case .prep: return "Share agenda before the meeting"
        case .summary: return "Share outcomes after the meeting"
        }
    }

    var icon: String {
        switch self {
        case .prep: return "list.clipboard"
        case .summary: return "doc.text.fill"
        }
    }
}

// MARK: - Export Section (v2.8)

enum ExportSection: String, Codable, CaseIterable, Identifiable {
    case header
    case agenda
    case lastMeetingRecap
    case goalsProgress
    case wentWell
    case didntGoWell
    case blockers
    case escalations
    case actionItems
    case nextSteps

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .header: return "Header"
        case .agenda: return "Agenda"
        case .lastMeetingRecap: return "Last Meeting Recap"
        case .goalsProgress: return "Goals & Progress"
        case .wentWell: return "What Went Well"
        case .didntGoWell: return "What Didn't Go Well"
        case .blockers: return "Blockers"
        case .escalations: return "Escalations"
        case .actionItems: return "Action Items"
        case .nextSteps: return "Next Steps"
        }
    }

    /// Default icon for professional style
    var defaultIcon: String {
        switch self {
        case .header: return ""
        case .agenda: return "AGENDA"
        case .lastMeetingRecap: return "LAST MEETING"
        case .goalsProgress: return "GOALS & PROGRESS"
        case .wentWell: return "WHAT WENT WELL"
        case .didntGoWell: return "CHALLENGES"
        case .blockers: return "BLOCKERS"
        case .escalations: return "ESCALATIONS"
        case .actionItems: return "ACTION ITEMS"
        case .nextSteps: return "NEXT STEPS"
        }
    }

    /// Casual style emoji
    var casualEmoji: String {
        switch self {
        case .header: return ""
        case .agenda: return "📋"
        case .lastMeetingRecap: return "📝"
        case .goalsProgress: return "🎯"
        case .wentWell: return "✅"
        case .didntGoWell: return "⚠️"
        case .blockers: return "🚧"
        case .escalations: return "🔺"
        case .actionItems: return "📌"
        case .nextSteps: return "➡️"
        }
    }

    /// Sections included in prep template
    static var prepSections: [ExportSection] {
        [.header, .agenda, .lastMeetingRecap, .goalsProgress, .actionItems]
    }

    /// Sections included in summary template
    static var summarySections: [ExportSection] {
        [.header, .wentWell, .didntGoWell, .blockers, .escalations, .actionItems, .nextSteps]
    }
}

// MARK: - AI Note Improvement (v2.9)

/// Types of AI improvements available for notes
enum NoteImprovementType: String, CaseIterable, Identifiable {
    case professionalTone = "professional"
    case expandDetails = "expand"
    case fixGrammar = "grammar"
    case simplify = "simplify"
    case addContext = "context"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .professionalTone: return "Professional Tone"
        case .expandDetails: return "Expand Details"
        case .fixGrammar: return "Fix Grammar"
        case .simplify: return "Simplify"
        case .addContext: return "Add Context"
        }
    }

    var icon: String {
        switch self {
        case .professionalTone: return "briefcase.fill"
        case .expandDetails: return "text.append"
        case .fixGrammar: return "textformat.abc"
        case .simplify: return "text.justify.left"
        case .addContext: return "doc.text.magnifyingglass"
        }
    }

    var description: String {
        switch self {
        case .professionalTone: return "Make it sound more professional"
        case .expandDetails: return "Add more detail and depth"
        case .fixGrammar: return "Correct spelling and grammar"
        case .simplify: return "Make it clearer and more concise"
        case .addContext: return "Add relevant context and background"
        }
    }
}

/// Meeting sections that can be improved with AI
enum MeetingSectionType: String, CaseIterable, Identifiable {
    case notes
    case wentWell
    case didntGoWell
    case blockers
    case escalations
    case thisWeekGoals
    case thisWeekProgress
    case keyMetrics
    case nextWeekGoals

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notes: return "Notes"
        case .wentWell: return "What Went Well"
        case .didntGoWell: return "What Didn't Go Well"
        case .blockers: return "Blockers"
        case .escalations: return "Escalations"
        case .thisWeekGoals: return "This Week's Goals"
        case .thisWeekProgress: return "Progress Updates"
        case .keyMetrics: return "Key Metrics"
        case .nextWeekGoals: return "Next Week's Goals"
        }
    }

    var icon: String {
        switch self {
        case .notes: return "note.text"
        case .wentWell: return "hand.thumbsup.fill"
        case .didntGoWell: return "hand.thumbsdown.fill"
        case .blockers: return "exclamationmark.octagon.fill"
        case .escalations: return "arrow.up.circle.fill"
        case .thisWeekGoals: return "list.clipboard.fill"
        case .thisWeekProgress: return "chart.bar.fill"
        case .keyMetrics: return "chart.line.uptrend.xyaxis"
        case .nextWeekGoals: return "arrow.right.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .notes: return .primary
        case .wentWell: return .green
        case .didntGoWell: return .orange
        case .blockers: return .red
        case .escalations: return .blue
        case .thisWeekGoals: return .blue
        case .thisWeekProgress: return .purple
        case .keyMetrics: return .orange
        case .nextWeekGoals: return .teal
        }
    }
}
