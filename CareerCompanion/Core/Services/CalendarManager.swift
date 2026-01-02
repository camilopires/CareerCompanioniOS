import EventKit
import Foundation

/// Manages calendar integration using EventKit
@MainActor
final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    // MARK: - Published Properties

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private let eventStore = EKEventStore()

    // MARK: - Initialization

    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current authorization status
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .writeOnly {
            loadCalendars()
        }
    }

    /// Request calendar access
    func requestAccess() async -> Bool {
        do {
            // iOS 17+ uses requestFullAccessToEvents
            let granted = try await eventStore.requestFullAccessToEvents()
            updateAuthorizationStatus()
            return granted
        } catch {
            self.error = error
            return false
        }
    }

    /// Check if we have permission to create events
    var canCreateEvents: Bool {
        authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
    }

    // MARK: - Calendars

    /// Load available calendars for events
    func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }

    /// Get the default calendar or the first writable one
    var defaultCalendar: EKCalendar? {
        eventStore.defaultCalendarForNewEvents ?? availableCalendars.first
    }

    /// Get a calendar by identifier
    func calendar(withIdentifier identifier: String) -> EKCalendar? {
        eventStore.calendar(withIdentifier: identifier)
    }

    // MARK: - Event Creation

    /// Create a calendar event for a meeting
    func createEvent(
        for meeting: Meeting,
        managerName: String,
        calendarIdentifier: String? = nil
    ) async throws -> String {
        guard canCreateEvents else {
            throw CalendarError.notAuthorized
        }

        let selectedCalendar = calendarIdentifier.flatMap { self.calendar(withIdentifier: $0) }
            ?? defaultCalendar

        guard let targetCalendar = selectedCalendar else {
            throw CalendarError.noCalendarAvailable
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = targetCalendar
        event.title = "1:1 with \(managerName)"
        event.startDate = meeting.date
        event.endDate = meeting.date.addingTimeInterval(30 * 60) // 30 minutes default
        event.notes = buildEventNotes(meeting: meeting)

        // Add a reminder based on user preference
        let reminderMinutes = UserDefaults.standard.integer(forKey: "meetingReminderMinutes")
        if reminderMinutes > 0 {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-reminderMinutes * 60))
            event.addAlarm(alarm)
        }

        try eventStore.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    /// Update an existing calendar event
    func updateEvent(eventID: String, with meeting: Meeting, managerName: String) async throws {
        guard canCreateEvents else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: eventID) else {
            throw CalendarError.eventNotFound
        }

        event.title = "1:1 with \(managerName)"
        event.startDate = meeting.date
        event.endDate = meeting.date.addingTimeInterval(30 * 60)
        event.notes = buildEventNotes(meeting: meeting)

        try eventStore.save(event, span: .thisEvent)
    }

    /// Delete a calendar event
    func deleteEvent(eventID: String) async throws {
        guard canCreateEvents else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: eventID) else {
            // Event might have been deleted manually, that's okay
            return
        }

        try eventStore.remove(event, span: .thisEvent)
    }

    // MARK: - Helpers

    /// Build event notes from meeting data
    private func buildEventNotes(meeting: Meeting) -> String {
        var notes: [String] = []

        if !meeting.notes.isEmpty {
            notes.append("Notes:\n\(meeting.notes)")
        }

        if !meeting.wentWell.isEmpty {
            notes.append("\nWhat went well:\n" + meeting.wentWell.map { "• \($0)" }.joined(separator: "\n"))
        }

        if !meeting.blockers.isEmpty {
            notes.append("\nBlockers:\n" + meeting.blockers.map { "• \($0)" }.joined(separator: "\n"))
        }

        return notes.isEmpty ? "1:1 Meeting - Career Companion" : notes.joined(separator: "\n")
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case notAuthorized
    case noCalendarAvailable
    case eventNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized. Please enable access in Settings."
        case .noCalendarAvailable:
            return "No writable calendar available."
        case .eventNotFound:
            return "Calendar event not found. It may have been deleted."
        case .saveFailed:
            return "Failed to save calendar event."
        }
    }
}

// MARK: - Calendar Settings

extension CalendarManager {
    /// Whether calendar sync is enabled
    var isSyncEnabled: Bool {
        get { AppSettings.shared.syncMeetingsToCalendar }
        set { AppSettings.shared.syncMeetingsToCalendar = newValue }
    }

    /// The selected calendar identifier
    var selectedCalendarID: String? {
        get { AppSettings.shared.selectedCalendarID }
        set { AppSettings.shared.selectedCalendarID = newValue }
    }
}
