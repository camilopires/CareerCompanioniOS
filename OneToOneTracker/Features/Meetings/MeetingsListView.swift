import SwiftUI

/// List of all 1:1 meetings (past and upcoming)
struct MeetingsListView: View {
    @StateObject private var viewModel = MeetingsViewModel()
    @State private var showingNewMeeting = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.allMeetings.isEmpty {
                LoadingView()
            } else if viewModel.allMeetings.isEmpty {
                EmptyMeetingsView(onAddMeeting: { showingNewMeeting = true })
            } else {
                MeetingsList(viewModel: viewModel)
            }
        }
        .navigationTitle("1:1 Meetings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingNewMeeting = true }) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Schedule meeting")
                }
            }
        }
        .sheet(isPresented: $showingNewMeeting) {
            NewMeetingView { meeting in
                Task {
                    await viewModel.createMeeting(meeting)
                }
            }
        }
        .refreshable {
            await viewModel.loadMeetings()
        }
        .task {
            await viewModel.loadMeetings()
        }
    }
}

// MARK: - Meetings List

private struct MeetingsList: View {
    @ObservedObject var viewModel: MeetingsViewModel

    var body: some View {
        List {
            // Upcoming meetings
            if !viewModel.upcomingMeetings.isEmpty {
                Section {
                    ForEach(viewModel.upcomingMeetings) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            MeetingRowView(meeting: meeting)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteMeetings(at: indexSet, from: viewModel.upcomingMeetings)
                        }
                    }
                } header: {
                    Text("Upcoming")
                }
            }

            // Past meetings
            if !viewModel.pastMeetings.isEmpty {
                Section {
                    ForEach(viewModel.pastMeetings) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            MeetingRowView(meeting: meeting)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteMeetings(at: indexSet, from: viewModel.pastMeetings)
                        }
                    }
                } header: {
                    Text("Past")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Meeting Row

struct MeetingRowView: View {
    let meeting: Meeting

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(meeting.status.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(meeting.formattedDate)
                    .font(Typography.body)
                    .foregroundStyle(Colors.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Label(meeting.status.displayName, systemImage: meeting.status.icon)
                        .font(Typography.caption1)
                        .foregroundStyle(meeting.status.color)

                    if let sentiment = meeting.meetingSentimentValue {
                        Text(sentiment.emoji)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // Chevron is provided by NavigationLink
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.formattedDate), \(meeting.status.displayName)")
    }
}

// MARK: - Empty State

private struct EmptyMeetingsView: View {
    let onAddMeeting: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            EmptyState(
                icon: "person.2",
                title: "No 1:1 Meetings",
                message: "Schedule your first 1:1 meeting to start tracking your conversations with your manager.",
                actionTitle: "Schedule Meeting",
                action: onAddMeeting
            )
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        ProgressView("Loading meetings...")
    }
}

// MARK: - New Meeting View

struct NewMeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date().addingTimeInterval(86400 * 7) // Default to 1 week from now
    @State private var managerName = ""
    let onCreate: (Meeting) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting Details") {
                    DatePicker("Date & Time", selection: $date)
                }

                Section("Manager") {
                    TextField("Manager Name", text: $managerName)
                }
            }
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let meeting = Meeting(
                            managerID: UUID(), // Would link to actual manager
                            date: date
                        )
                        onCreate(meeting)
                        dismiss()
                    }
                    .disabled(managerName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Meetings List") {
    NavigationStack {
        MeetingsListView()
    }
}

#Preview("Meeting Row") {
    let scheduledMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 2)
    )
    let completedMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(-86400 * 7),
        status: .completed
    )
    return List {
        MeetingRowView(meeting: scheduledMeeting)
        MeetingRowView(meeting: completedMeeting)
    }
}
