import Foundation
import SwiftUI

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
            loadSampleData()
        }

        isLoading = false
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

    // MARK: - Sample Data

    private func loadSampleData() {
        agendaItems = AgendaItem.samples.map { item in
            var copy = item
            copy.meetingID = meeting.id
            return copy
        }
    }
}
