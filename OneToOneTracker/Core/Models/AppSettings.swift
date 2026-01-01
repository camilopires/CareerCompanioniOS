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
    }
}
