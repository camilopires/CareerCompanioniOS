import Foundation
import SwiftUI
import CloudKit

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

        do {
            let items: [AgendaItem] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "meetingRef == %@", meeting.recordID),
                sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)]
            )
            agendaItems = items
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

        // Fetch from CloudKit
        do {
            let managerRecordID = CKRecord.ID(recordName: meeting.managerID.uuidString)
            let managerRef = CKRecord.Reference(recordID: managerRecordID, action: .none)

            let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(
                    format: "managerRef == %@ AND status == %@ AND date < %@",
                    managerRef,
                    MeetingStatus.completed.rawValue,
                    meeting.date as NSDate
                ),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
                limit: 1
            )
            return meetings.first
        } catch {
            return nil
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

        do {
            // Update meeting with all data
            var updatedMeeting = meeting
            updatedMeeting.status = .completed
            updatedMeeting.notes = notes
            updatedMeeting.wentWell = wentWell
            updatedMeeting.didntGoWell = didntGoWell
            updatedMeeting.blockers = blockers
            updatedMeeting.escalations = escalations
            updatedMeeting.thisWeekGoals = thisWeekGoals
            updatedMeeting.thisWeekProgress = thisWeekProgress
            updatedMeeting.keyMetrics = keyMetrics
            updatedMeeting.nextWeekGoals = nextWeekGoals
            updatedMeeting.weekSentiment = weekSentiment
            updatedMeeting.meetingSentiment = meetingSentiment
            updatedMeeting.updatedAt = Date()

            _ = try await CloudKitManager.shared.save(updatedMeeting)

            // Save all agenda items (with completion status)
            for item in agendaItems {
                _ = try await CloudKitManager.shared.save(item)
            }

            // Save all new action items
            for item in newActionItems {
                _ = try await CloudKitManager.shared.save(item)
            }

            // Create achievements from "what went well" items
            await createAchievementsFromWins()

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
}
