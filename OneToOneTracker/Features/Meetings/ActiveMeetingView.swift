import SwiftUI

/// View for conducting an active 1:1 meeting
struct ActiveMeetingView: View {
    @StateObject private var viewModel: ActiveMeetingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false

    init(meeting: Meeting) {
        self._viewModel = StateObject(wrappedValue: ActiveMeetingViewModel(meeting: meeting))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Timer
                MeetingTimer(startTime: viewModel.startTime)

                // Agenda checklist
                AgendaChecklistSection(viewModel: viewModel)

                // This Week's Goals (optional, auto-populated from previous meeting)
                FeedbackListSection(
                    title: "This Week's Goals",
                    icon: "list.clipboard.fill",
                    iconColor: .blue,
                    items: $viewModel.thisWeekGoals,
                    placeholder: "Add a goal for this week..."
                )

                // Progress Updates (optional)
                FeedbackListSection(
                    title: "Progress Updates",
                    icon: "chart.bar.fill",
                    iconColor: .purple,
                    items: $viewModel.thisWeekProgress,
                    placeholder: "Add a progress update..."
                )

                // Key Metrics (optional, carries over between meetings)
                FeedbackListSection(
                    title: "Key Metrics",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .orange,
                    items: $viewModel.keyMetrics,
                    placeholder: "Add a metric you're tracking..."
                )

                // Next Week's Goals (optional, carries to next meeting)
                FeedbackListSection(
                    title: "Next Week's Goals",
                    icon: "arrow.right.circle.fill",
                    iconColor: .teal,
                    items: $viewModel.nextWeekGoals,
                    placeholder: "Add a goal for next week..."
                )

                // Notes
                NotesSection(notes: $viewModel.notes)

                // What went well
                FeedbackListSection(
                    title: "What Went Well",
                    icon: "hand.thumbsup.fill",
                    iconColor: Colors.success,
                    items: $viewModel.wentWell,
                    placeholder: "Add a win..."
                )

                // What didn't go well
                FeedbackListSection(
                    title: "What Didn't Go Well",
                    icon: "hand.thumbsdown.fill",
                    iconColor: Colors.warning,
                    items: $viewModel.didntGoWell,
                    placeholder: "Add a challenge..."
                )

                // Blockers
                FeedbackListSection(
                    title: "Blockers",
                    icon: "exclamationmark.octagon.fill",
                    iconColor: Colors.error,
                    items: $viewModel.blockers,
                    placeholder: "Add a blocker..."
                )

                // Escalations
                FeedbackListSection(
                    title: "Escalations for Manager",
                    icon: "arrow.up.circle.fill",
                    iconColor: Colors.info,
                    items: $viewModel.escalations,
                    placeholder: "Add an escalation..."
                )

                // Action Items
                MeetingActionItemsSection(viewModel: viewModel)

                // Sentiments
                SentimentsSection(viewModel: viewModel)

                // Complete button
                Button(action: { showingEndConfirmation = true }) {
                    Label("Complete Meeting", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Spacing.lg)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle("1:1 Meeting")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            "End Meeting",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("Complete Meeting") {
                Task {
                    await viewModel.completeMeeting()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will save all notes and mark the meeting as complete.")
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Meeting Timer

private struct MeetingTimer: View {
    let startTime: Date

    @State private var elapsed: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formattedTime: String {
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(formattedTime)
                .font(Typography.timer)
                .foregroundStyle(Color.accentColor)
                .monospacedDigit()

            Text("Meeting Duration")
                .font(Typography.caption1)
                .foregroundStyle(Colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        .onReceive(timer) { _ in
            elapsed = Date().timeIntervalSince(startTime)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meeting duration: \(formattedTime)")
    }
}

// MARK: - Agenda Checklist

private struct AgendaChecklistSection: View {
    @ObservedObject var viewModel: ActiveMeetingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Agenda", systemImage: "list.bullet.clipboard")
                .font(Typography.headline)

            if viewModel.agendaItems.isEmpty {
                CompactEmptyState(icon: "list.bullet", message: "No agenda items")
            } else {
                VStack(spacing: 0) {
                    ForEach($viewModel.agendaItems) { $item in
                        AgendaChecklistRow(item: $item)

                        if item.id != viewModel.agendaItems.last?.id {
                            Divider()
                                .padding(.leading, Spacing.touchTarget)
                        }
                    }
                }
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
        }
    }
}

private struct AgendaChecklistRow: View {
    @Binding var item: AgendaItem

    var body: some View {
        Button(action: { item.isCompleted.toggle() }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? Colors.success : Colors.textTertiary)
                    .font(.title3)

                Text(item.title)
                    .font(Typography.body)
                    .foregroundStyle(item.isCompleted ? Colors.textSecondary : Colors.textPrimary)
                    .strikethrough(item.isCompleted)

                Spacer()
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(item.isCompleted ? "completed" : "not completed")")
        .accessibilityAddTraits(item.isCompleted ? [.isSelected] : [])
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Notes", systemImage: "note.text")
                .font(Typography.headline)

            TextEditor(text: $notes)
                .font(Typography.body)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                .accessibilityLabel("Meeting notes")
        }
    }
}

// MARK: - Feedback List Section

struct FeedbackListSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    var items: Binding<[String]>
    let placeholder: String

    @State private var newItem = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: icon)
                .font(Typography.headline)
                .foregroundStyle(iconColor)

            VStack(spacing: Spacing.sm) {
                ForEach(items.wrappedValue.indices, id: \.self) { index in
                    HStack {
                        Text("•")
                            .foregroundStyle(iconColor)

                        Text(items.wrappedValue[index])
                            .font(Typography.body)

                        Spacer()

                        Button(action: {
                            items.wrappedValue.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Colors.textTertiary)
                        }
                        .accessibilityLabel("Remove item")
                    }
                }

                HStack {
                    TextField(placeholder, text: $newItem)
                        .font(Typography.body)
                        .submitLabel(.done)
                        .onSubmit(addItem)

                    if !newItem.isEmpty {
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
    }

    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        items.wrappedValue.append(newItem)
        newItem = ""
        Theme.lightHaptic()
    }
}

// MARK: - Meeting Action Items Section

private struct MeetingActionItemsSection: View {
    @ObservedObject var viewModel: ActiveMeetingViewModel
    @State private var showingAddActionItem = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Action Items", systemImage: "checklist")
                    .font(Typography.headline)

                Spacer()

                Button(action: { showingAddActionItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add action item")
            }

            if viewModel.newActionItems.isEmpty {
                CompactEmptyState(icon: "checklist", message: "No action items yet")
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.newActionItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(item.title)
                                    .font(Typography.body)

                                HStack(spacing: Spacing.sm) {
                                    Label(item.owner.displayName, systemImage: item.owner.icon)
                                    if let date = item.formattedDueDate {
                                        Label(date, systemImage: "calendar")
                                    }
                                }
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)
                            }

                            Spacer()

                            Button(action: {
                                viewModel.removeActionItem(item)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Colors.textTertiary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddActionItem) {
            QuickAddActionItemView { item in
                viewModel.addActionItem(item)
            }
        }
    }
}

// MARK: - Sentiments Section

private struct SentimentsSection: View {
    @ObservedObject var viewModel: ActiveMeetingViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            SentimentPicker(
                selectedSentiment: $viewModel.weekSentiment,
                label: "How was your week?"
            )

            SentimentPicker(
                selectedSentiment: $viewModel.meetingSentiment,
                label: "How was this 1:1?"
            )
        }
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }
}

// MARK: - Quick Add Action Item

struct QuickAddActionItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var owner: Owner = .me
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var hasDueDate = true

    let onAdd: (ActionItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs to be done?", text: $title)
                }

                Section {
                    Picker("Owner", selection: $owner) {
                        ForEach(Owner.allCases) { owner in
                            Label(owner.displayName, systemImage: owner.icon)
                                .tag(owner)
                        }
                    }

                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Action Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = ActionItem(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            owner: owner
                        )
                        onAdd(item)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Active Meeting") {
    let previewMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 2)
    )
    return NavigationStack {
        ActiveMeetingView(meeting: previewMeeting)
    }
}
