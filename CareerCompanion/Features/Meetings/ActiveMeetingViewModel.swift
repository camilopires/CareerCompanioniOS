import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the active meeting view
@MainActor
final class ActiveMeetingViewModel: ObservableObject {

    // MARK: - Properties

    let meeting: Meeting
    let startTime: Date

    @Published var agendaItems: [AgendaItem] = []
    @Published var notes: String = ""
    @Published var wentWell: [String] = []
    @Published var didntGoWell: [String] = []
    @Published var blockers: [String] = []
    @Published var escalations: [String] = []
    @Published var thisWeekGoals: [String] = []
    @Published var thisWeekProgress: [String] = []
    @Published var keyMetrics: [String] = []
    @Published var nextWeekGoals: [String] = []
    @Published var newActionItems: [ActionItem] = []
    @Published var weekSentiment: Int? = nil
    @Published var meetingSentiment: Int? = nil
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }
    private var sdMeeting: SDMeeting?
    private var sdAgendaItems: [UUID: SDAgendaItem] = [:]

    // MARK: - Initialization

    init(meeting: Meeting) {
        self.meeting = meeting
        self.startTime = Date()

        // Pre-populate from existing meeting data
        self.notes = meeting.notes
        self.wentWell = meeting.wentWell
        self.didntGoWell = meeting.didntGoWell
        self.blockers = meeting.blockers
        self.escalations = meeting.escalations
        self.thisWeekGoals = meeting.thisWeekGoals
        self.thisWeekProgress = meeting.thisWeekProgress
        self.keyMetrics = meeting.keyMetrics
        self.nextWeekGoals = meeting.nextWeekGoals
        self.weekSentiment = meeting.weekSentiment
        self.meetingSentiment = meeting.meetingSentiment
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        if AppSettings.shared.isDemoMode {
            agendaItems = []
            await loadCarryOverData()
            isLoading = false
            return
        }

        do {
            // Find the SDMeeting
            let meetingID = meeting.id
            let meetingPredicate = #Predicate<SDMeeting> { $0.id == meetingID }
            var descriptor = FetchDescriptor<SDMeeting>(predicate: meetingPredicate)
            descriptor.fetchLimit = 1
            if let foundMeeting = try context.fetch(descriptor).first {
                sdMeeting = foundMeeting

                // Get agenda items from the meeting relationship
                let items = foundMeeting.agendaItems.sorted { $0.order < $1.order }
                agendaItems = items.map { $0.toAgendaItem() }
                sdAgendaItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            }
        } catch {
            self.error = error
        }

        // Auto-populate goals and metrics from previous meeting if empty
        await loadCarryOverData()

        isLoading = false
    }

    /// Loads data from the previous meeting with the same person for carry-over
    private func loadCarryOverData() async {
        // Only carry over if fields are empty (don't overwrite user edits)
        guard thisWeekGoals.isEmpty || keyMetrics.isEmpty else { return }

        if let previousMeeting = await loadPreviousMeeting() {
            // Carry over: next week's goals → this week's goals
            if thisWeekGoals.isEmpty && !previousMeeting.nextWeekGoals.isEmpty {
                thisWeekGoals = previousMeeting.nextWeekGoals
            }

            // Carry over: key metrics persist across meetings
            if keyMetrics.isEmpty && !previousMeeting.keyMetrics.isEmpty {
                keyMetrics = previousMeeting.keyMetrics
            }
        }
    }

    /// Fetches the most recent completed meeting with the same person
    private func loadPreviousMeeting() async -> Meeting? {
        // In demo mode, find previous meeting from demo data
        if AppSettings.shared.isDemoMode {
            return DemoDataProvider.meetings
                .filter { $0.managerID == meeting.managerID && $0.status == .completed && $0.date < meeting.date }
                .sorted { $0.date > $1.date }
                .first
        }

        // Fetch from SwiftData
        do {
            let managerID = meeting.managerID
            let meetingDate = meeting.date
            let predicate = #Predicate<SDMeeting> { sdMeeting in
                sdMeeting.manager?.id == managerID &&
                sdMeeting.statusRaw == "completed" &&
                sdMeeting.date < meetingDate
            }
            var descriptor = FetchDescriptor<SDMeeting>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            if let foundMeeting = try context.fetch(descriptor).first {
                return foundMeeting.toMeeting()
            }
        } catch {
            // Ignore error, return nil
        }
        return nil
    }

    // MARK: - Agenda Items

    func addAgendaItem(title: String) async {
        let newItem = AgendaItem(
            meetingID: meeting.id,
            title: title,
            order: agendaItems.count
        )

        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            agendaItems.append(newItem)
            Theme.lightHaptic()
            return
        }

        do {
            let sdItem = SDAgendaItem(
                id: newItem.id,
                meeting: sdMeeting,
                title: newItem.title,
                notes: newItem.notes,
                isCompleted: newItem.isCompleted,
                order: newItem.order,
                createdAt: newItem.createdAt
            )
            context.insert(sdItem)
            try DataManager.shared.save()

            sdAgendaItems[sdItem.id] = sdItem
            agendaItems.append(newItem)
            Theme.lightHaptic()
        } catch {
            self.error = error
        }
    }

    // MARK: - Action Items

    func addActionItem(_ item: ActionItem) {
        var itemWithMeeting = item
        itemWithMeeting.meetingID = meeting.id
        newActionItems.append(itemWithMeeting)
        Theme.lightHaptic()
    }

    func removeActionItem(_ item: ActionItem) {
        newActionItems.removeAll { $0.id == item.id }
    }

    // MARK: - Complete Meeting

    func completeMeeting() async {
        isLoading = true

        // In demo mode, just show success (data is in-memory only)
        if AppSettings.shared.isDemoMode {
            WatchSessionManager.shared.clearActiveMeeting()
            Theme.successHaptic()
            isLoading = false
            return
        }

        do {
            // Find or ensure we have the SDMeeting
            if sdMeeting == nil {
                let meetingID = meeting.id
                let meetingPredicate = #Predicate<SDMeeting> { $0.id == meetingID }
                var descriptor = FetchDescriptor<SDMeeting>(predicate: meetingPredicate)
                descriptor.fetchLimit = 1
                sdMeeting = try context.fetch(descriptor).first
            }

            guard let sdMeeting = sdMeeting else {
                throw NSError(domain: "ActiveMeetingViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Meeting not found"])
            }

            // Update meeting with all data
            sdMeeting.status = .completed
            sdMeeting.notes = notes
            sdMeeting.wentWell = wentWell
            sdMeeting.didntGoWell = didntGoWell
            sdMeeting.blockers = blockers
            sdMeeting.escalations = escalations
            sdMeeting.thisWeekGoals = thisWeekGoals
            sdMeeting.thisWeekProgress = thisWeekProgress
            sdMeeting.keyMetrics = keyMetrics
            sdMeeting.nextWeekGoals = nextWeekGoals
            sdMeeting.weekSentiment = weekSentiment
            sdMeeting.meetingSentiment = meetingSentiment
            sdMeeting.updatedAt = Date()

            // Update all agenda items (with completion status)
            for item in agendaItems {
                if let sdItem = sdAgendaItems[item.id] {
                    sdItem.update(from: item)
                }
            }

            // Save all new action items
            for item in newActionItems {
                let sdActionItem = SDActionItem(
                    id: item.id,
                    meeting: sdMeeting,
                    title: item.title,
                    itemDescription: item.itemDescription,
                    dueDate: item.dueDate,
                    priority: item.priority,
                    status: item.status,
                    owner: item.owner,
                    links: item.links,
                    createdAt: item.createdAt
                )
                context.insert(sdActionItem)
            }

            try DataManager.shared.save()

            // Create achievements from "what went well" items
            await createAchievementsFromWins()

            // Auto-schedule next meeting if this is a recurring meeting
            await scheduleNextRecurringMeeting(from: sdMeeting.toMeeting())

            // Clear Watch
            WatchSessionManager.shared.clearActiveMeeting()

            Theme.successHaptic()

        } catch {
            self.error = error
            Theme.errorHaptic()
        }

        isLoading = false
    }

    private func createAchievementsFromWins() async {
        // Optionally prompt user to convert wins to achievements
        // For now, we'll just save them as meeting data
    }

    /// Creates the next occurrence of a recurring meeting
    private func scheduleNextRecurringMeeting(from meeting: Meeting) async {
        guard let rule = meeting.recurrence else { return }

        // Calculate next meeting date
        let nextDate = rule.nextDate(from: meeting.date)

        // Create new meeting with same properties
        let nextMeeting = SDMeeting(
            manager: sdMeeting?.manager,
            date: nextDate,
            status: .scheduled,
            perspective: meeting.perspective,
            meetingType: meeting.meetingType,
            recurrence: meeting.recurrence
        )

        context.insert(nextMeeting)

        do {
            try DataManager.shared.save()
        } catch {
            print("Failed to schedule next recurring meeting: \(error)")
        }
    }
}
