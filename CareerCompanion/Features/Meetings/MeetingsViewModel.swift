import Foundation
import SwiftUI

/// Filter for relationship types
enum RelationshipFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case myManagers = "My Managers"
    case directReports = "Direct Reports"
    case others = "Others"

    var id: String { rawValue }
}

/// ViewModel for the meetings list
@MainActor
final class MeetingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var allMeetings: [Meeting] = []
    @Published var managers: [Manager] = []
    @Published var selectedManagerID: UUID?
    @Published var relationshipFilter: RelationshipFilter = .all
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    /// People matching the current relationship filter
    var filteredPeople: [Manager] {
        switch relationshipFilter {
        case .all:
            return managers
        case .myManagers:
            return managers.filter { $0.isMyManager }
        case .directReports:
            return managers.filter { $0.isDirectReport }
        case .others:
            return managers.filter { $0.isOtherRelationship }
        }
    }

    /// Meetings filtered by selected manager or relationship type
    var filteredMeetings: [Meeting] {
        var meetings = allMeetings

        // Apply relationship filter first
        if relationshipFilter != .all {
            let personIDs = Set(filteredPeople.map { $0.id })
            meetings = meetings.filter { personIDs.contains($0.managerID) }
        }

        // Then apply specific person filter if selected
        if let managerID = selectedManagerID {
            meetings = meetings.filter { $0.managerID == managerID }
        }

        return meetings
    }

    var upcomingMeetings: [Meeting] {
        filteredMeetings
            .filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
    }

    var pastMeetings: [Meeting] {
        filteredMeetings
            .filter { $0.isPast }
            .sorted { $0.date > $1.date }
    }

    /// Get manager by ID
    func manager(for id: UUID) -> Manager? {
        managers.first { $0.id == id }
    }

    /// Get manager name by ID
    func managerName(for id: UUID) -> String {
        manager(for: id)?.name ?? "Unknown"
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            managers = DemoDataProvider.managers
            allMeetings = DemoDataProvider.meetings
            isLoading = false
            return
        }

        do {
            async let fetchedManagers: [Manager] = CloudKitManager.shared.fetch()
            async let fetchedMeetings: [Meeting] = CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )

            managers = try await fetchedManagers
            allMeetings = try await fetchedMeetings
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadMeetings() async {
        await loadData()
    }

    // MARK: - Actions

    func createMeeting(_ meeting: Meeting) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            allMeetings.insert(meeting, at: 0)
            Theme.successHaptic()
            return
        }

        do {
            var meetingToSave = meeting

            // Sync to calendar if enabled
            if AppSettings.shared.syncMeetingsToCalendar {
                let managerName = self.managerName(for: meeting.managerID)
                if let eventID = try? await CalendarManager.shared.createEvent(
                    for: meeting,
                    managerName: managerName,
                    calendarIdentifier: AppSettings.shared.selectedCalendarID
                ) {
                    meetingToSave.calendarEventID = eventID
                }
            }

            let saved = try await CloudKitManager.shared.save(meetingToSave)
            allMeetings.insert(saved, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func updateMeeting(_ meeting: Meeting) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            if let index = allMeetings.firstIndex(where: { $0.id == meeting.id }) {
                allMeetings[index] = meeting
            }
            return
        }

        do {
            // Update calendar event if synced
            if let eventID = meeting.calendarEventID {
                let managerName = self.managerName(for: meeting.managerID)
                try? await CalendarManager.shared.updateEvent(
                    eventID: eventID,
                    with: meeting,
                    managerName: managerName
                )
            }

            let saved = try await CloudKitManager.shared.save(meeting)
            if let index = allMeetings.firstIndex(where: { $0.id == saved.id }) {
                allMeetings[index] = saved
            }
        } catch {
            self.error = error
        }
    }

    func deleteMeetings(at offsets: IndexSet, from meetings: [Meeting]) async {
        let meetingsToDelete = offsets.map { meetings[$0] }

        for meeting in meetingsToDelete {
            // In demo mode, only update in-memory
            if AppSettings.shared.isDemoMode {
                allMeetings.removeAll { $0.id == meeting.id }
                continue
            }

            do {
                // Delete calendar event if synced
                if let eventID = meeting.calendarEventID {
                    try? await CalendarManager.shared.deleteEvent(eventID: eventID)
                }

                try await CloudKitManager.shared.delete(meeting)
                allMeetings.removeAll { $0.id == meeting.id }
            } catch {
                self.error = error
            }
        }
    }

    func startMeeting(_ meeting: Meeting) async {
        var updated = meeting
        updated.status = .inProgress
        await updateMeeting(updated)
    }

    func completeMeeting(_ meeting: Meeting) async {
        var updated = meeting
        updated.status = .completed
        updated.updatedAt = Date()
        await updateMeeting(updated)
    }
}
