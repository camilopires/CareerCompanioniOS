import Foundation
import SwiftUI

@MainActor
final class WatchHomeViewModel: ObservableObject {
    @Published var nextMeeting: Meeting?
    @Published var upcomingMeetings: [Meeting] = []
    @Published var openActionItems: [ActionItem] = []
    @Published var managers: [Manager] = []
    @Published var isLoading = false
    @Published var lastSentiment: Sentiment?

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Check if demo mode (shared with main app via App Groups)
        let isDemoMode = UserDefaults(suiteName: "group.com.onetoone.tracker")?.bool(forKey: "isDemoMode") ?? false

        if isDemoMode {
            loadDemoData()
        } else {
            await loadCloudKitData()
        }
    }

    private func loadDemoData() {
        // Load demo data
        managers = DemoDataProvider.managers

        let allMeetings = DemoDataProvider.meetings
        upcomingMeetings = allMeetings
            .filter { $0.status == .scheduled && $0.date > Date() }
            .sorted { $0.date < $1.date }
        nextMeeting = upcomingMeetings.first

        openActionItems = DemoDataProvider.actionItems
            .filter { $0.status != .completed }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func loadCloudKitData() async {
        do {
            // Fetch managers
            managers = try await CloudKitManager.shared.fetch()

            // Fetch upcoming meetings
            let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status == %@ AND date > %@",
                                       MeetingStatus.scheduled.rawValue,
                                       Date() as NSDate),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)]
            )
            upcomingMeetings = meetings
            nextMeeting = meetings.first

            // Fetch open action items
            openActionItems = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status != %@", ActionItemStatus.completed.rawValue),
                sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)]
            )
        } catch {
            print("Watch: Failed to load data: \(error)")
        }
    }

    func managerName(for meeting: Meeting) -> String {
        managers.first { $0.id == meeting.managerID }?.name ?? "Manager"
    }

    func completeActionItem(_ item: ActionItem) async {
        var updatedItem = item
        updatedItem.status = .completed
        updatedItem.completedAt = Date()

        // Update locally first
        if let index = openActionItems.firstIndex(where: { $0.id == item.id }) {
            openActionItems.remove(at: index)
        }

        // Sync to CloudKit
        let isDemoMode = UserDefaults(suiteName: "group.com.onetoone.tracker")?.bool(forKey: "isDemoMode") ?? false
        if !isDemoMode {
            do {
                try await CloudKitManager.shared.save(updatedItem)
            } catch {
                print("Watch: Failed to complete action item: \(error)")
            }
        }
    }

    func logSentiment(_ sentiment: Sentiment, for meeting: Meeting?) async {
        lastSentiment = sentiment

        guard let meeting = meeting ?? nextMeeting else { return }

        var updatedMeeting = meeting
        updatedMeeting.weekSentiment = sentiment.rawValue

        let isDemoMode = UserDefaults(suiteName: "group.com.onetoone.tracker")?.bool(forKey: "isDemoMode") ?? false
        if !isDemoMode {
            do {
                try await CloudKitManager.shared.save(updatedMeeting)
            } catch {
                print("Watch: Failed to log sentiment: \(error)")
            }
        }
    }
}
