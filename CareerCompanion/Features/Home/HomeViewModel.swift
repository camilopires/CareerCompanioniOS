import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var actionItems: [ActionItem] = []
    @Published var nextMeeting: Meeting?
    @Published var manager: Manager?
    @Published var allManagers: [Manager] = []
    @Published var upcomingOtherMeetings: [Meeting] = []
    @Published var activeGoals: [CareerGoal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showPrivacyBanner: Bool

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }
    private var sdActionItems: [UUID: SDActionItem] = [:]

    /// People with "Other" relationship types (not My Manager or Direct Report)
    var otherPeople: [Manager] {
        allManagers.filter { $0.isOtherRelationship }
    }

    // MARK: - Computed Properties

    var openActionItems: [ActionItem] {
        actionItems
            .filter { $0.status != .completed }
            .sorted { item1, item2 in
                // Sort by: overdue first, then by due date, then by priority
                if item1.isOverdue != item2.isOverdue {
                    return item1.isOverdue
                }
                if let date1 = item1.dueDate, let date2 = item2.dueDate {
                    return date1 < date2
                }
                if item1.dueDate != nil && item2.dueDate == nil {
                    return true
                }
                return item1.priority.sortOrder < item2.priority.sortOrder
            }
    }

    var openActionItemsCount: Int {
        actionItems.filter { $0.status != .completed }.count
    }

    var overdueCount: Int {
        actionItems.filter { $0.isOverdue }.count
    }

    var completedThisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return actionItems.filter { item in
            guard let completedAt = item.completedAt else { return false }
            return completedAt >= startOfWeek
        }.count
    }

    var meetingStreak: Int {
        Self.calculateAppVisitStreak()
    }

    // MARK: - App Visit Streak

    private static let visitedDatesKey = "appVisitedDates"

    /// Records today's visit and returns the updated streak
    static func recordAppVisit() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var visitedDates = getVisitedDates()

        // Add today if not already recorded
        if !visitedDates.contains(today) {
            visitedDates.append(today)
            // Keep only last 365 days to prevent unbounded growth
            let cutoff = calendar.date(byAdding: .day, value: -365, to: today)!
            visitedDates = visitedDates.filter { $0 >= cutoff }
            visitedDates.sort()
            saveVisitedDates(visitedDates)
        }
    }

    /// Calculates consecutive days visiting the app (including today)
    static func calculateAppVisitStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let visitedDates = Set(getVisitedDates())

        // If user hasn't visited today, check if they visited yesterday to continue streak
        // Otherwise streak is 0
        var checkDate = today
        if !visitedDates.contains(today) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if !visitedDates.contains(yesterday) {
                return 0
            }
            checkDate = yesterday
        }

        // Count consecutive days backwards from checkDate
        var streak = 0
        while visitedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }

    private static func getVisitedDates() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: visitedDatesKey),
              let dates = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }
        return dates
    }

    private static func saveVisitedDates(_ dates: [Date]) {
        if let data = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(data, forKey: visitedDatesKey)
        }
    }

    var activeGoalsCount: Int {
        activeGoals.filter { $0.isActive }.count
    }

    var overallGoalsProgress: Double {
        guard !activeGoals.isEmpty else { return 0 }
        let totalProgress = activeGoals.reduce(0) { $0 + $1.progress }
        return Double(totalProgress) / Double(activeGoals.count * 100)
    }

    // MARK: - Initialization

    init() {
        self.showPrivacyBanner = !UserDefaults.standard.bool(forKey: "hasSeenPrivacyBanner")
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Record app visit for streak tracking
        Self.recordAppVisit()

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            actionItems = DemoDataProvider.actionItems
            allManagers = DemoDataProvider.managers
            manager = allManagers.first { $0.isMyManager }
            activeGoals = DemoDataProvider.careerGoals.filter { $0.isActive }

            // Get upcoming meetings
            let upcomingMeetings = DemoDataProvider.meetings
                .filter { $0.status == .scheduled }
                .sorted { $0.date < $1.date }

            // Next meeting with "My Manager"
            let myManagerIDs = Set(allManagers.filter { $0.isMyManager }.map { $0.id })
            nextMeeting = upcomingMeetings.first { myManagerIDs.contains($0.managerID) }

            // Upcoming meetings with other people (mentors, peers, etc.)
            let otherPersonIDs = Set(otherPeople.map { $0.id })
            upcomingOtherMeetings = Array(upcomingMeetings.filter { otherPersonIDs.contains($0.managerID) }.prefix(3))

            updateCachedCounts()
            isLoading = false
            return
        }

        do {
            // Fetch action items
            let fetchedActionItems = try DataManager.shared.fetchActionItems()
            actionItems = fetchedActionItems.map { $0.toActionItem() }
            sdActionItems = Dictionary(uniqueKeysWithValues: fetchedActionItems.map { ($0.id, $0) })

            // Fetch managers
            let fetchedManagers = try DataManager.shared.fetchManagers()
            allManagers = fetchedManagers.map { $0.toManager() }
            manager = allManagers.first { $0.isMyManager }

            // Fetch upcoming meetings
            let scheduledPredicate = #Predicate<SDMeeting> { meeting in
                meeting.statusRaw == "scheduled"
            }
            let allUpcomingMeetings = try context.fetch(
                FetchDescriptor<SDMeeting>(
                    predicate: scheduledPredicate,
                    sortBy: [SortDescriptor(\.date)]
                )
            ).map { $0.toMeeting() }

            // Next meeting with "My Manager"
            let myManagerIDs = Set(allManagers.filter { $0.isMyManager }.map { $0.id })
            nextMeeting = allUpcomingMeetings.first { myManagerIDs.contains($0.managerID) }

            // Upcoming meetings with other people (mentors, peers, etc.)
            let otherPersonIDs = Set(otherPeople.map { $0.id })
            upcomingOtherMeetings = Array(allUpcomingMeetings.filter { otherPersonIDs.contains($0.managerID) }.prefix(3))

            // Fetch active goals
            let activeGoalsPredicate = #Predicate<SDCareerGoal> { goal in
                goal.statusRaw == "inProgress" || goal.statusRaw == "notStarted"
            }
            let fetchedGoals = try context.fetch(
                FetchDescriptor<SDCareerGoal>(predicate: activeGoalsPredicate)
            )
            activeGoals = fetchedGoals.map { $0.toCareerGoal() }

            updateCachedCounts()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func updateCachedCounts() {
        // Cache counts for premium limit checking
        AppSettings.shared.cachedPeopleCount = allManagers.count
        AppSettings.shared.cachedActionItemCount = actionItems.filter { $0.status != .completed }.count
        AppSettings.shared.cachedGoalCount = activeGoals.filter { $0.isActive }.count
    }

    func refresh() async {
        await loadData()
    }

    /// Get the manager/person for a given meeting
    func person(for meeting: Meeting) -> Manager? {
        allManagers.first { $0.id == meeting.managerID }
    }

    // MARK: - Actions

    func dismissPrivacyBanner() {
        showPrivacyBanner = false
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyBanner")
    }

    func completeActionItem(_ item: ActionItem) async {
        var updatedItem = item
        updatedItem.markComplete()

        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            if let index = actionItems.firstIndex(where: { $0.id == item.id }) {
                actionItems[index] = updatedItem
            }
            updateCachedCounts()
            Theme.successHaptic()
            return
        }

        do {
            if let sdItem = sdActionItems[item.id] {
                sdItem.update(from: updatedItem)
                try DataManager.shared.save()
            }

            if let index = actionItems.firstIndex(where: { $0.id == item.id }) {
                actionItems[index] = updatedItem
            }
            updateCachedCounts()
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }
}
