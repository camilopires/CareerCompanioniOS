import Foundation
import SwiftUI

/// ViewModel for the meetings list
@MainActor
final class MeetingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var allMeetings: [Meeting] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var upcomingMeetings: [Meeting] {
        allMeetings
            .filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
    }

    var pastMeetings: [Meeting] {
        allMeetings
            .filter { $0.isPast }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Data Loading

    func loadMeetings() async {
        isLoading = true
        error = nil

        do {
            let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )
            allMeetings = meetings
        } catch {
            self.error = error
            // Load sample data for preview
            loadSampleData()
        }

        isLoading = false
    }

    // MARK: - Actions

    func createMeeting(_ meeting: Meeting) async {
        do {
            let saved = try await CloudKitManager.shared.save(meeting)
            allMeetings.insert(saved, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func updateMeeting(_ meeting: Meeting) async {
        do {
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
            do {
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

    // MARK: - Sample Data

    private func loadSampleData() {
        allMeetings = [
            Meeting.sample,
            Meeting.sampleCompleted,
            Meeting(
                managerID: UUID(),
                date: Date().addingTimeInterval(-86400 * 14),
                status: .completed,
                wentWell: ["Finished the sprint early"],
                weekSentiment: 3,
                meetingSentiment: 4
            )
        ]
    }
}
