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

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            allMeetings = DemoDataProvider.meetings
            isLoading = false
            return
        }

        do {
            let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )
            allMeetings = meetings
        } catch {
            self.error = error
        }

        isLoading = false
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
            let saved = try await CloudKitManager.shared.save(meeting)
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
