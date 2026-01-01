import Foundation
import SwiftUI

/// ViewModel for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var actionItems: [ActionItem] = []
    @Published var nextMeeting: Meeting?
    @Published var manager: Manager?
    @Published var activeGoals: [CareerGoal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showPrivacyBanner: Bool

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
        // TODO: Calculate actual streak from meeting history
        3
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

        do {
            async let fetchedActionItems: [ActionItem] = CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )
            async let fetchedManagers: [Manager] = CloudKitManager.shared.fetch()
            async let fetchedMeetings: [Meeting] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status == %@", MeetingStatus.scheduled.rawValue),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
                limit: 1
            )
            async let fetchedGoals: [CareerGoal] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status IN %@", [GoalStatus.inProgress.rawValue, GoalStatus.notStarted.rawValue])
            )

            actionItems = try await fetchedActionItems
            let managers = try await fetchedManagers
            manager = managers.first
            nextMeeting = try await fetchedMeetings.first
            activeGoals = try await fetchedGoals

        } catch {
            self.error = error
            // Load sample data for preview/testing
            loadSampleData()
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Actions

    func dismissPrivacyBanner() {
        showPrivacyBanner = false
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyBanner")
    }

    func completeActionItem(_ item: ActionItem) async {
        var updatedItem = item
        updatedItem.markComplete()

        do {
            let saved = try await CloudKitManager.shared.save(updatedItem)
            if let index = actionItems.firstIndex(where: { $0.id == saved.id }) {
                actionItems[index] = saved
            }
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        actionItems = ActionItem.samples
        manager = Manager.sample
        nextMeeting = Meeting.sample
        activeGoals = CareerGoal.samples
    }
}
