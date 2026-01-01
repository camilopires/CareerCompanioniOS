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
            AddMeetingView(managers: viewModel.managers) { meeting in
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
            // Relationship type filter
            Section {
                Picker("Filter by", selection: $viewModel.relationshipFilter) {
                    ForEach(RelationshipFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Person filter picker (within selected relationship type)
            if viewModel.filteredPeople.count > 1 {
                Section {
                    PersonFilterPicker(
                        people: viewModel.filteredPeople,
                        selectedPersonID: $viewModel.selectedManagerID
                    )
                }
            }

            // Upcoming meetings
            if !viewModel.upcomingMeetings.isEmpty {
                Section {
                    ForEach(viewModel.upcomingMeetings) { meeting in
                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                            MeetingRowView(
                                meeting: meeting,
                                managerName: viewModel.managerName(for: meeting.managerID)
                            )
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
                            MeetingRowView(
                                meeting: meeting,
                                managerName: viewModel.managerName(for: meeting.managerID)
                            )
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

// MARK: - Person Filter Picker

private struct PersonFilterPicker: View {
    let people: [Manager]
    @Binding var selectedPersonID: UUID?

    var body: some View {
        Picker("Person", selection: $selectedPersonID) {
            Text("All")
                .tag(nil as UUID?)

            ForEach(people) { person in
                HStack {
                    Text(person.name)
                    Text("(\(person.relationshipType))")
                        .foregroundStyle(Color.secondary)
                }
                .tag(person.id as UUID?)
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - Meeting Row

struct MeetingRowView: View {
    let meeting: Meeting
    var managerName: String = ""

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(meeting.status.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(meeting.formattedDate)
                        .font(Typography.body)
                        .foregroundStyle(Colors.textPrimary)

                    if !managerName.isEmpty {
                        Text("with \(managerName)")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    // Meeting type badge
                    Text(meeting.meetingType)
                        .font(Typography.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(4)

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
        .accessibilityLabel("\(meeting.formattedDate)\(managerName.isEmpty ? "" : " with \(managerName)"), \(meeting.meetingType), \(meeting.status.displayName)")
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
                message: "Schedule your first 1:1 meeting to start tracking your conversations.",
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

// MARK: - Add Meeting View

struct AddMeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date().addingTimeInterval(86400 * 7) // Default to 1 week from now
    @State private var selectedManagerID: UUID?
    @State private var meetingType: String = "1:1"
    @State private var showingAddMeetingType = false
    @State private var newMeetingTypeName = ""

    let managers: [Manager]
    let onCreate: (Meeting) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting Details") {
                    DatePicker("Date & Time", selection: $date)

                    Picker("Type", selection: $meetingType) {
                        ForEach(AppSettings.shared.allMeetingTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    Button {
                        newMeetingTypeName = ""
                        showingAddMeetingType = true
                    } label: {
                        Label("Add Custom Type", systemImage: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }

                Section {
                    if managers.isEmpty {
                        Text("No people found. Add someone in Settings first.")
                            .foregroundStyle(Colors.textSecondary)
                    } else {
                        Picker("With", selection: $selectedManagerID) {
                            Text("Select a person")
                                .tag(nil as UUID?)

                            ForEach(managers) { manager in
                                HStack {
                                    Text(manager.name)
                                    Text("(\(manager.relationshipType))")
                                        .foregroundStyle(Colors.textSecondary)
                                }
                                .tag(manager.id as UUID?)
                            }
                        }
                    }
                } header: {
                    Text("Person")
                } footer: {
                    if managers.isEmpty {
                        Text("Go to Settings > People to add someone.")
                    }
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
                        guard let managerID = selectedManagerID else { return }
                        let perspective: MeetingPerspective = AppSettings.shared.userRole == .individualContributor
                            ? .asEmployee
                            : .asManager
                        let meeting = Meeting(
                            managerID: managerID,
                            date: date,
                            perspective: perspective,
                            meetingType: meetingType
                        )
                        onCreate(meeting)
                        dismiss()
                    }
                    .disabled(selectedManagerID == nil)
                }
            }
            .onAppear {
                // Pre-select first manager if only one exists
                if managers.count == 1 {
                    selectedManagerID = managers.first?.id
                }
            }
            .alert("Add Meeting Type", isPresented: $showingAddMeetingType) {
                TextField("Type name", text: $newMeetingTypeName)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if !newMeetingTypeName.isEmpty {
                        AppSettings.shared.addCustomMeetingType(newMeetingTypeName)
                        meetingType = newMeetingTypeName
                    }
                }
            } message: {
                Text("Enter a name for the new meeting type.")
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
        MeetingRowView(meeting: scheduledMeeting, managerName: "Sarah Johnson")
        MeetingRowView(meeting: completedMeeting, managerName: "Michael Chen")
    }
}

#Preview("Add Meeting") {
    AddMeetingView(
        managers: [
            Manager(name: "Sarah Johnson", email: "sarah@company.com", relationshipType: "My Manager"),
            Manager(name: "Michael Chen", email: "michael@company.com", relationshipType: "Mentor")
        ]
    ) { _ in }
}
