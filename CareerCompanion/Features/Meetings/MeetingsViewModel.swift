import Foundation
import SwiftUI
import SwiftData

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

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }

    // Store SDMeeting references for updates
    private var sdMeetings: [UUID: SDMeeting] = [:]
    private var sdManagers: [UUID: SDManager] = [:]

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
            // Fetch managers from SwiftData
            let fetchedSDManagers = try DataManager.shared.fetchManagers()
            managers = fetchedSDManagers.map { $0.toManager() }

            // Store references for updates
            sdManagers = Dictionary(uniqueKeysWithValues: fetchedSDManagers.map { ($0.id, $0) })

            // Fetch meetings from SwiftData
            let fetchedSDMeetings = try DataManager.shared.fetchMeetings()
            allMeetings = fetchedSDMeetings.map { $0.toMeeting() }

            // Store references for updates
            sdMeetings = Dictionary(uniqueKeysWithValues: fetchedSDMeetings.map { ($0.id, $0) })
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

            // Find the SDManager - fetch from SwiftData if not cached
            var sdManager = sdManagers[meeting.managerID]
            if sdManager == nil {
                let managerID = meeting.managerID
                let predicate = #Predicate<SDManager> { $0.id == managerID }
                let descriptor = FetchDescriptor<SDManager>(predicate: predicate)
                if let fetchedManager = try? context.fetch(descriptor).first {
                    sdManager = fetchedManager
                    sdManagers[managerID] = fetchedManager
                }
            }

            // Ensure manager is in managers array for immediate UI display
            if let sdManager = sdManager {
                let manager = sdManager.toManager()
                if !managers.contains(where: { $0.id == manager.id }) {
                    managers.append(manager)
                }
            }

            // Create SDMeeting
            let sdMeeting = SDMeeting(
                id: meetingToSave.id,
                manager: sdManager,
                date: meetingToSave.date,
                status: meetingToSave.status,
                perspective: meetingToSave.perspective,
                meetingType: meetingToSave.meetingType,
                notes: meetingToSave.notes,
                wentWell: meetingToSave.wentWell,
                didntGoWell: meetingToSave.didntGoWell,
                blockers: meetingToSave.blockers,
                escalations: meetingToSave.escalations,
                thisWeekGoals: meetingToSave.thisWeekGoals,
                thisWeekProgress: meetingToSave.thisWeekProgress,
                keyMetrics: meetingToSave.keyMetrics,
                nextWeekGoals: meetingToSave.nextWeekGoals,
                weekSentiment: meetingToSave.weekSentiment,
                meetingSentiment: meetingToSave.meetingSentiment,
                calendarEventID: meetingToSave.calendarEventID,
                recurrence: meetingToSave.recurrence,
                createdAt: meetingToSave.createdAt,
                updatedAt: meetingToSave.updatedAt
            )

            context.insert(sdMeeting)
            try DataManager.shared.save()

            // Store reference and update local list
            sdMeetings[sdMeeting.id] = sdMeeting
            allMeetings.insert(meetingToSave, at: 0)
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

            // Find and update the SDMeeting
            if let sdMeeting = sdMeetings[meeting.id] {
                sdMeeting.update(from: meeting)
                try DataManager.shared.save()
            }

            if let index = allMeetings.firstIndex(where: { $0.id == meeting.id }) {
                allMeetings[index] = meeting
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

                // Delete from SwiftData
                if let sdMeeting = sdMeetings[meeting.id] {
                    context.delete(sdMeeting)
                    try DataManager.shared.save()
                    sdMeetings.removeValue(forKey: meeting.id)
                }

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

        // Send meeting to Watch
        let managerName = self.managerName(for: meeting.managerID)
        let actionItems = await fetchRelevantActionItems(for: meeting.managerID)
        WatchSessionManager.shared.sendActiveMeeting(updated, managerName: managerName, actionItems: actionItems)
    }

    /// Fetches open action items associated with a manager/person
    private func fetchRelevantActionItems(for managerID: UUID) async -> [ActionItem] {
        if AppSettings.shared.isDemoMode {
            return DemoDataProvider.actionItems.filter { $0.status != .completed }
        }

        do {
            let fetchedItems = try DataManager.shared.fetchActionItems()
            return fetchedItems
                .filter { $0.status != .completed }
                .map { $0.toActionItem() }
        } catch {
            return []
        }
    }

    func completeMeeting(_ meeting: Meeting) async {
        var updated = meeting
        updated.status = .completed
        updated.updatedAt = Date()
        await updateMeeting(updated)

        // Clear Watch
        WatchSessionManager.shared.clearActiveMeeting()

        // Auto-schedule next meeting if this is a recurring meeting
        await scheduleNextRecurringMeeting(from: meeting)
    }

    /// Creates the next occurrence of a recurring meeting
    private func scheduleNextRecurringMeeting(from meeting: Meeting) async {
        guard let rule = meeting.recurrence else { return }

        // Calculate next meeting date
        let nextDate = rule.nextDate(from: meeting.date)

        // Create new meeting with same properties
        let nextMeeting = Meeting(
            managerID: meeting.managerID,
            date: nextDate,
            perspective: meeting.perspective,
            meetingType: meeting.meetingType,
            recurrence: meeting.recurrence
        )

        // Save to SwiftData
        await createMeeting(nextMeeting)
    }

    // MARK: - Manager CRUD

    func createManager(_ manager: Manager) async {
        if AppSettings.shared.isDemoMode {
            managers.append(manager)
            return
        }

        do {
            let sdManager = SDManager(from: manager)
            context.insert(sdManager)
            try DataManager.shared.save()

            sdManagers[manager.id] = sdManager
            managers.append(manager)
        } catch {
            self.error = error
        }
    }
}
