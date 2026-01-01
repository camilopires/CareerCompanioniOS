import Foundation
import SwiftUI

/// Central app settings using @Observable pattern for v2.0
/// Manages user role (IC/Manager), app mode, and onboarding state
@Observable
final class AppSettings {
    static let shared = AppSettings()

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
    }
}
