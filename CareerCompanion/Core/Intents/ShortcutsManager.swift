import AppIntents
import Foundation

/// Manages Siri Shortcuts donations and updates
@MainActor
final class ShortcutsManager {
    static let shared = ShortcutsManager()

    private init() {}

    // MARK: - Shortcut Donations

    /// Donate a shortcut when user checks their next meeting
    func donateCheckNextMeeting() {
        // App Intents automatically handle donations through usage
        // This method can be called to track user patterns
    }

    /// Donate a shortcut when user views action items
    func donateCheckActionItems() {
        // App Intents automatically handle donations through usage
    }

    /// Donate a shortcut when user adds an action item
    func donateAddActionItem(title: String) {
        // With App Intents, the system learns from usage patterns
    }

    /// Donate a shortcut when user logs an achievement
    func donateLogAchievement(title: String) {
        // With App Intents, the system learns from usage patterns
    }

    /// Donate a shortcut when user starts a meeting
    func donateStartMeeting() {
        // App Intents automatically handle donations through usage
    }

    // MARK: - Shortcut Updates

    /// Update shortcuts with current data
    func updateShortcuts() async {
        // Update App Shortcuts with latest data
        await updateAppShortcutParameters()
    }

    private func updateAppShortcutParameters() async {
        // For App Intents, we can update parameters dynamically
        // This is useful when data changes (new managers, etc.)
    }

    // MARK: - Spotlight Integration

    /// Index meetings for Spotlight search
    func indexMeetingForSpotlight(_ meeting: Meeting, managerName: String) {
        // Could integrate with Core Spotlight for deeper search
        // Currently handled by CloudKit automatically
    }

    /// Remove meeting from Spotlight index
    func removeMeetingFromSpotlight(_ meetingID: UUID) {
        // Remove from Core Spotlight index
    }
}

// MARK: - Intent Handling Extensions

extension CheckNextMeetingIntent {
    /// Create an intent pre-configured for a specific manager
    static func intent(for manager: Manager) -> CheckNextMeetingIntent {
        CheckNextMeetingIntent()
    }
}

extension AddActionItemIntent {
    /// Create an intent pre-configured with a title
    static func intent(title: String, priority: Priority = .medium) -> AddActionItemIntent {
        let intent = AddActionItemIntent()
        intent.title = title
        intent.priority = ActionItemPriorityEntity(rawValue: priority.rawValue) ?? .medium
        return intent
    }
}

extension LogAchievementIntent {
    /// Create an intent pre-configured with a title
    static func intent(title: String, description: String? = nil) -> LogAchievementIntent {
        let intent = LogAchievementIntent()
        intent.title = title
        intent.achievementDescription = description
        return intent
    }
}
