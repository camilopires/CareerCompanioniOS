import Foundation
import SwiftUI

/// Central app settings using @Observable pattern for v2.0
/// Manages user role (IC/Manager), app mode, onboarding state, and custom types
@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Default Types

    /// Default relationship types (special ones first that drive app mode, then others)
    static let defaultRelationshipTypes = [
        "My Manager",           // Special: drives IC mode
        "Direct Report",        // Special: drives Manager mode
        "Mentor",
        "Peer",
        "Stakeholder",
        "Skip-Level Manager",
        "Cross-Team Partner",
        "External Coach"
    ]

    /// Default meeting types
    static let defaultMeetingTypes = [
        "1:1",
        "Career Development",
        "Project Sync",
        "Feedback Session",
        "Mentorship",
        "Coffee Chat"
    ]

    // MARK: - User Role

    /// Current user role - Individual Contributor or Manager
    var userRole: UserRole {
        get {
            guard let value = UserDefaults.standard.string(forKey: "userRole"),
                  let role = UserRole(rawValue: value) else {
                return .individualContributor
            }
            return role
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "userRole")
        }
    }

    /// Convenience property to check if user is in manager mode
    var isManagerMode: Bool {
        userRole == .manager
    }

    // MARK: - Demo Mode

    /// Whether the app is showing demo data
    /// When true, views show in-memory sample data instead of CloudKit data
    var isDemoMode: Bool {
        get { UserDefaults.standard.bool(forKey: "isDemoMode") }
        set { UserDefaults.standard.set(newValue, forKey: "isDemoMode") }
    }

    /// Whether user has seen the demo mode during onboarding
    var hasExploredDemo: Bool {
        get { UserDefaults.standard.bool(forKey: "hasExploredDemo") }
        set { UserDefaults.standard.set(newValue, forKey: "hasExploredDemo") }
    }

    // MARK: - Onboarding

    /// Whether user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Calendar Settings

    /// Whether to sync meetings to system calendar
    var syncMeetingsToCalendar: Bool {
        get { UserDefaults.standard.bool(forKey: "syncMeetingsToCalendar") }
        set { UserDefaults.standard.set(newValue, forKey: "syncMeetingsToCalendar") }
    }

    /// Selected calendar identifier for sync
    var selectedCalendarID: String? {
        get { UserDefaults.standard.string(forKey: "selectedCalendarID") }
        set { UserDefaults.standard.set(newValue, forKey: "selectedCalendarID") }
    }

    // MARK: - Premium Trial (v2.4)

    /// Date when the free trial started (nil = never started)
    var trialStartDate: Date? {
        get { UserDefaults.standard.object(forKey: "trialStartDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "trialStartDate") }
    }

    // MARK: - Cached Entity Counts (for limit checking)

    /// Cached count of people (managers/reports)
    var cachedPeopleCount: Int {
        get { UserDefaults.standard.integer(forKey: "cachedPeopleCount") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedPeopleCount") }
    }

    /// Cached count of active action items
    var cachedActionItemCount: Int {
        get { UserDefaults.standard.integer(forKey: "cachedActionItemCount") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedActionItemCount") }
    }

    /// Cached count of active career goals
    var cachedGoalCount: Int {
        get { UserDefaults.standard.integer(forKey: "cachedGoalCount") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedGoalCount") }
    }

    /// Cached count of achievements
    var cachedAchievementCount: Int {
        get { UserDefaults.standard.integer(forKey: "cachedAchievementCount") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedAchievementCount") }
    }

    // MARK: - Cached Premium Status (updated by SubscriptionManager)

    /// Cached premium access status (updated by SubscriptionManager to avoid main actor issues)
    var cachedHasPremiumAccess: Bool {
        get { UserDefaults.standard.bool(forKey: "cachedHasPremiumAccess") }
        set { UserDefaults.standard.set(newValue, forKey: "cachedHasPremiumAccess") }
    }

    // MARK: - Feature Access

    /// Whether user can add more people (premium or under limit)
    var canAddMorePeople: Bool {
        cachedHasPremiumAccess || cachedPeopleCount < PremiumFeatures.maxFreePeople
    }

    /// Whether user can add more action items (premium or under limit)
    var canAddMoreActionItems: Bool {
        cachedHasPremiumAccess || cachedActionItemCount < PremiumFeatures.maxFreeActionItems
    }

    /// Whether user can add more career goals (premium or under limit)
    var canAddMoreGoals: Bool {
        cachedHasPremiumAccess || cachedGoalCount < PremiumFeatures.maxFreeGoals
    }

    /// Whether user can add more achievements (premium or under limit)
    var canAddMoreAchievements: Bool {
        cachedHasPremiumAccess || cachedAchievementCount < PremiumFeatures.maxFreeAchievements
    }

    /// Whether user can access weekly goals and metrics sections
    var canAccessWeeklyGoals: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can access performance reports
    var canAccessReports: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can access Apple Watch app
    var canAccessWatch: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can sync to calendar
    var canAccessCalendarSync: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can export/import data
    var canExportData: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can create custom types
    var canUseCustomTypes: Bool {
        cachedHasPremiumAccess
    }

    /// Whether user can access AI suggestions
    var canAccessAI: Bool {
        cachedHasPremiumAccess
    }

    // MARK: - Custom Types (v2.2)

    /// User-created relationship types (stored in UserDefaults)
    var customRelationshipTypes: [String] {
        get { UserDefaults.standard.stringArray(forKey: "customRelationshipTypes") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "customRelationshipTypes") }
    }

    /// User-created meeting types (stored in UserDefaults)
    var customMeetingTypes: [String] {
        get { UserDefaults.standard.stringArray(forKey: "customMeetingTypes") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "customMeetingTypes") }
    }

    /// All available relationship types (defaults + custom, deduplicated)
    var allRelationshipTypes: [String] {
        var types = Self.defaultRelationshipTypes
        for custom in customRelationshipTypes where !types.contains(custom) {
            types.append(custom)
        }
        return types
    }

    /// All available meeting types (defaults + custom, deduplicated)
    var allMeetingTypes: [String] {
        var types = Self.defaultMeetingTypes
        for custom in customMeetingTypes where !types.contains(custom) {
            types.append(custom)
        }
        return types
    }

    /// Add a custom relationship type
    func addCustomRelationshipType(_ type: String) {
        guard !type.isEmpty, !allRelationshipTypes.contains(type) else { return }
        customRelationshipTypes.append(type)
    }

    /// Add a custom meeting type
    func addCustomMeetingType(_ type: String) {
        guard !type.isEmpty, !allMeetingTypes.contains(type) else { return }
        customMeetingTypes.append(type)
    }

    /// Remove a custom relationship type (cannot remove defaults)
    func removeCustomRelationshipType(_ type: String) {
        guard !Self.defaultRelationshipTypes.contains(type) else { return }
        customRelationshipTypes.removeAll { $0 == type }
    }

    /// Remove a custom meeting type (cannot remove defaults)
    func removeCustomMeetingType(_ type: String) {
        guard !Self.defaultMeetingTypes.contains(type) else { return }
        customMeetingTypes.removeAll { $0 == type }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Reset

    /// Reset all settings to defaults
    func resetToDefaults() {
        userRole = .individualContributor
        isDemoMode = false
        hasExploredDemo = false
        hasCompletedOnboarding = false
        syncMeetingsToCalendar = false
        selectedCalendarID = nil
        customRelationshipTypes = []
        customMeetingTypes = []
        // Note: trialStartDate is NOT reset to preserve trial state
        cachedPeopleCount = 0
        cachedActionItemCount = 0
        cachedGoalCount = 0
        cachedAchievementCount = 0
    }
}
