import Foundation

/// Premium tier limits and feature flags
enum PremiumFeatures {
    // MARK: - Free Tier Limits
    static let maxFreePeople = 1
    static let maxFreeActionItems = 10
    static let maxFreeGoals = 3
    static let maxFreeAchievements = 5
    static let maxFreeMeetingHistory = 10

    // MARK: - Trial
    static let trialDurationDays = 30

    // MARK: - Product IDs
    static let premiumLifetimeProductID = "com.careercompanion.app.premium.lifetime"
}

/// Features that require premium
enum PremiumFeature: String, CaseIterable, Identifiable {
    case unlimitedPeople = "Unlimited People"
    case unlimitedActionItems = "Unlimited Action Items"
    case unlimitedGoals = "Unlimited Career Goals"
    case unlimitedAchievements = "Unlimited Achievements"
    case fullMeetingHistory = "Full Meeting History"
    case weeklyGoalsMetrics = "Weekly Goals & Metrics"
    case performanceReports = "Performance Reports"
    case aiSuggestions = "AI Suggestions"
    case appleWatch = "Apple Watch App"
    case allWidgets = "All Widget Sizes"
    case calendarSync = "Calendar Sync"
    case exportImport = "Export & Import"
    case customTypes = "Custom Types"
    case allSiriShortcuts = "All Siri Shortcuts"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .unlimitedPeople: return "person.3.fill"
        case .unlimitedActionItems: return "checklist"
        case .unlimitedGoals: return "target"
        case .unlimitedAchievements: return "star.fill"
        case .fullMeetingHistory: return "clock.fill"
        case .weeklyGoalsMetrics: return "chart.bar.fill"
        case .performanceReports: return "doc.text.fill"
        case .aiSuggestions: return "sparkles"
        case .appleWatch: return "applewatch"
        case .allWidgets: return "square.grid.2x2.fill"
        case .calendarSync: return "calendar"
        case .exportImport: return "square.and.arrow.up"
        case .customTypes: return "tag.fill"
        case .allSiriShortcuts: return "mic.fill"
        }
    }

    var description: String {
        switch self {
        case .unlimitedPeople: return "Track 1:1s with managers, mentors, peers, and more"
        case .unlimitedActionItems: return "Never hit a limit on action items"
        case .unlimitedGoals: return "Set as many career goals as you need"
        case .unlimitedAchievements: return "Record all your wins and accomplishments"
        case .fullMeetingHistory: return "Access your complete meeting history"
        case .weeklyGoalsMetrics: return "Track weekly goals and key metrics"
        case .performanceReports: return "Generate reports for performance reviews"
        case .aiSuggestions: return "Get smart agenda suggestions"
        case .appleWatch: return "Access meetings from your wrist"
        case .allWidgets: return "All widget sizes for your home screen"
        case .calendarSync: return "Sync meetings to your iOS calendar"
        case .exportImport: return "Backup and restore your data"
        case .customTypes: return "Create custom relationship and meeting types"
        case .allSiriShortcuts: return "Full Siri integration"
        }
    }
}
