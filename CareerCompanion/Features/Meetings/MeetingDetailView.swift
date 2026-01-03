import SwiftUI
import SwiftData

/// Detailed view of a past or scheduled meeting
struct MeetingDetailView: View {
    let meeting: Meeting
    var managerName: String = ""

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingActiveMeeting = false
    @State private var showingAgendaBuilder = false
    @State private var showingExport = false
    @State private var showingReschedule = false
    @State private var showingEditRecurrence = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSkipConfirmation = false

    // Data for context sections
    @State private var agendaItems: [String] = []
    @State private var openActionItems: [ActionItem] = []
    @State private var pastMeetings: [Meeting] = []
    @State private var meetingStreak: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Header card
                MeetingHeaderCard(meeting: meeting, managerName: managerName)

                if meeting.status == .completed {
                    // Completed meeting sections
                    CompletedMeetingContent(meeting: meeting)
                } else {
                    // Scheduled meeting content
                    ScheduledMeetingContent(
                        meeting: meeting,
                        managerName: managerName,
                        agendaItems: agendaItems,
                        openActionItems: openActionItems,
                        pastMeetings: pastMeetings,
                        meetingStreak: meetingStreak,
                        onStartMeeting: { showingActiveMeeting = true },
                        onPrepareAgenda: { showingAgendaBuilder = true },
                        onReschedule: { showingReschedule = true },
                        onSkip: { showingSkipConfirmation = true },
                        onEditRecurrence: { showingEditRecurrence = true },
                        onStartAdHoc: startAdHocMeeting,
                        onDelete: { showingDeleteConfirmation = true }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle(meeting.status == .completed ? "Meeting Details" : "Upcoming 1:1")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingExport = true
                } label: {
                    Image(systemName: "doc.on.doc")
                        .accessibilityLabel("Export meeting")
                }
            }
        }
        .task {
            await loadContextData()
        }
        .fullScreenCover(isPresented: $showingActiveMeeting) {
            NavigationStack {
                ActiveMeetingView(meeting: meeting)
            }
        }
        .sheet(isPresented: $showingAgendaBuilder) {
            NavigationStack {
                AgendaBuilderView(meeting: meeting)
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportMeetingView(
                meeting: meeting,
                managerName: managerName.isEmpty ? "Person" : managerName
            )
        }
        .sheet(isPresented: $showingReschedule) {
            RescheduleMeetingSheet(meeting: meeting)
        }
        .sheet(isPresented: $showingEditRecurrence) {
            EditRecurrenceSheet(meeting: meeting)
        }
        .alert("Skip This Meeting?", isPresented: $showingSkipConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Skip", role: .destructive) {
                skipMeeting()
            }
        } message: {
            Text("This meeting will be marked as skipped. The next occurrence will still be scheduled if this is a recurring meeting.")
        }
        .alert("Delete Meeting?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteMeeting()
            }
        } message: {
            Text(meeting.isRecurring ? "This will delete this meeting occurrence. Future meetings will still be scheduled." : "This meeting will be permanently deleted.")
        }
    }

    // MARK: - Data Loading

    private func loadContextData() async {
        // Load agenda items for this meeting
        if AppSettings.shared.isDemoMode {
            // Demo agenda items
            agendaItems = ["Review weekly progress", "Discuss blockers", "Plan next steps"]
        } else {
            do {
                let sdAgendaItems = try DataManager.shared.fetchAgendaItems(forMeetingID: meeting.id)
                agendaItems = sdAgendaItems.map { $0.title }
            } catch {
                agendaItems = []
            }
        }

        // Load past meetings with this person
        if AppSettings.shared.isDemoMode {
            pastMeetings = DemoDataProvider.meetings
                .filter { $0.managerID == meeting.managerID && $0.status == .completed }
                .sorted { $0.date > $1.date }
        } else {
            do {
                let allMeetings = try DataManager.shared.fetchMeetings()
                pastMeetings = allMeetings
                    .filter { $0.manager?.id == meeting.managerID && $0.toMeeting().status == .completed }
                    .map { $0.toMeeting() }
                    .sorted { $0.date > $1.date }
            } catch {
                pastMeetings = []
            }
        }

        // Calculate meeting streak (consecutive completed meetings)
        meetingStreak = calculateStreak()

        // Load open action items from meetings with this person
        if AppSettings.shared.isDemoMode {
            openActionItems = DemoDataProvider.actionItems.filter { $0.isOpen }
        } else {
            do {
                let allActionItems = try DataManager.shared.fetchActionItems()
                let meetingIDs = Set(pastMeetings.map { $0.id })
                openActionItems = allActionItems
                    .filter { item in
                        if let meetingID = item.meeting?.id {
                            return meetingIDs.contains(meetingID) && item.isOpen
                        }
                        return false
                    }
                    .map { $0.toActionItem() }
            } catch {
                openActionItems = []
            }
        }
    }

    private func calculateStreak() -> Int {
        var streak = 0
        let sortedMeetings = pastMeetings.sorted { $0.date > $1.date }

        for meeting in sortedMeetings {
            if meeting.status == .completed {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Actions

    private func startAdHocMeeting() {
        // Create a new meeting starting now
        let adHocMeeting = Meeting(
            managerID: meeting.managerID,
            date: Date(),
            perspective: meeting.perspective,
            meetingType: "Ad-hoc"
        )

        // Save and navigate to active meeting
        Task {
            if !AppSettings.shared.isDemoMode {
                let sdMeeting = SDMeeting(
                    id: adHocMeeting.id,
                    date: adHocMeeting.date,
                    status: adHocMeeting.status,
                    perspective: adHocMeeting.perspective,
                    meetingType: adHocMeeting.meetingType
                )
                modelContext.insert(sdMeeting)
                try? modelContext.save()
            }
            showingActiveMeeting = true
        }
    }

    private func skipMeeting() {
        Task {
            var updatedMeeting = meeting
            updatedMeeting.status = .skipped

            if !AppSettings.shared.isDemoMode {
                if let sdMeeting = try? DataManager.shared.fetchMeeting(by: meeting.id) {
                    sdMeeting.status = .skipped
                    try? DataManager.shared.save()
                }
            }

            Theme.successHaptic()
            dismiss()
        }
    }

    private func deleteMeeting() {
        Task {
            if !AppSettings.shared.isDemoMode {
                if let sdMeeting = try? DataManager.shared.fetchMeeting(by: meeting.id) {
                    modelContext.delete(sdMeeting)
                    try? modelContext.save()
                }
            }

            Theme.successHaptic()
            dismiss()
        }
    }
}

// MARK: - Header Card

private struct MeetingHeaderCard: View {
    let meeting: Meeting
    var managerName: String = ""

    private var timeUntilMeeting: String {
        let now = Date()
        let interval = meeting.date.timeIntervalSince(now)

        if interval < 0 {
            return "Started"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes <= 1 ? "Starting now" : "In \(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "In \(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "In \(days)d"
        }
    }

    private var recurrenceText: String? {
        guard let recurrence = meeting.recurrence else { return nil }
        return recurrence.displayText
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Person name if available
                if !managerName.isEmpty {
                    Text("Meeting with \(managerName)")
                        .font(Typography.subheadline)
                        .foregroundStyle(Colors.textSecondary)
                }

                // Date and time
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(meeting.date.formatted(date: .complete, time: .omitted))
                            .font(Typography.headline)

                        Text(meeting.date.formatted(date: .omitted, time: .shortened))
                            .font(Typography.body)
                            .foregroundStyle(Colors.textSecondary)
                    }

                    Spacer()

                    // Time until meeting or sentiment
                    if meeting.status == .completed {
                        if let sentiment = meeting.meetingSentimentValue {
                            VStack(spacing: Spacing.xxs) {
                                Text(sentiment.emoji)
                                    .font(.title)
                                Text("Rating")
                                    .font(Typography.caption2)
                                    .foregroundStyle(Colors.textTertiary)
                            }
                        }
                    } else {
                        Text(timeUntilMeeting)
                            .font(Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(meeting.date.timeIntervalSince(Date()) < 7200 ? Colors.warning : Colors.textSecondary)
                    }
                }

                // Meeting type and recurrence info
                HStack(spacing: Spacing.sm) {
                    // Meeting type badge
                    Text(meeting.meetingType)
                        .font(Typography.caption1)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Colors.primaryLight)
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())

                    // Recurrence badge
                    if let recurrenceText {
                        Label(recurrenceText, systemImage: "repeat")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textTertiary)
                    }

                    Spacer()

                    // Status
                    Label(meeting.status.displayName, systemImage: meeting.status.icon)
                        .font(Typography.caption1)
                        .foregroundStyle(meeting.status.color)
                }
            }
        }
    }
}

// MARK: - Scheduled Meeting Content

private struct ScheduledMeetingContent: View {
    let meeting: Meeting
    let managerName: String
    let agendaItems: [String]
    let openActionItems: [ActionItem]
    let pastMeetings: [Meeting]
    let meetingStreak: Int

    let onStartMeeting: () -> Void
    let onPrepareAgenda: () -> Void
    let onReschedule: () -> Void
    let onSkip: () -> Void
    let onEditRecurrence: () -> Void
    let onStartAdHoc: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Primary actions
            PrimaryActionsSection(
                onStartMeeting: onStartMeeting,
                onPrepareAgenda: onPrepareAgenda
            )

            // Quick actions
            QuickActionsSection(
                meeting: meeting,
                onReschedule: onReschedule,
                onSkip: onSkip,
                onEditRecurrence: onEditRecurrence,
                onStartAdHoc: onStartAdHoc,
                onDelete: onDelete
            )

            // Agenda preview
            if !agendaItems.isEmpty {
                AgendaPreviewSection(
                    items: agendaItems,
                    onPrepareAgenda: onPrepareAgenda
                )
            }

            // Open action items
            if !openActionItems.isEmpty {
                ActionItemsPreviewSection(items: openActionItems)
            }

            // Meeting history
            if !pastMeetings.isEmpty {
                MeetingHistorySection(
                    pastMeetings: pastMeetings,
                    streak: meetingStreak
                )
            }
        }
    }
}

// MARK: - Primary Actions Section

private struct PrimaryActionsSection: View {
    let onStartMeeting: () -> Void
    let onPrepareAgenda: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: onStartMeeting) {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: onPrepareAgenda) {
                Label("Prepare", systemImage: "list.bullet.clipboard")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

// MARK: - Quick Actions Section

private struct QuickActionsSection: View {
    let meeting: Meeting
    let onReschedule: () -> Void
    let onSkip: () -> Void
    let onEditRecurrence: () -> Void
    let onStartAdHoc: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Card {
            VStack(spacing: 0) {
                QuickActionRow(
                    icon: "calendar.badge.clock",
                    title: "Reschedule",
                    color: Colors.info,
                    action: onReschedule
                )

                Divider().padding(.leading, 44)

                QuickActionRow(
                    icon: "forward.fill",
                    title: "Skip This Meeting",
                    color: Colors.warning,
                    action: onSkip
                )

                if meeting.isRecurring {
                    Divider().padding(.leading, 44)

                    QuickActionRow(
                        icon: "repeat",
                        title: "Edit Recurrence",
                        color: Colors.textSecondary,
                        action: onEditRecurrence
                    )
                }

                Divider().padding(.leading, 44)

                QuickActionRow(
                    icon: "plus.circle.fill",
                    title: "Start Ad-hoc Meeting Now",
                    color: Colors.success,
                    action: onStartAdHoc
                )

                Divider().padding(.leading, 44)

                QuickActionRow(
                    icon: "trash",
                    title: "Delete Meeting",
                    color: Colors.error,
                    action: onDelete
                )
            }
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.lightHaptic()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)

                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(color == Colors.error ? color : Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Colors.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Agenda Preview Section

private struct AgendaPreviewSection: View {
    let items: [String]
    let onPrepareAgenda: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label("Agenda", systemImage: "list.bullet.clipboard")
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Colors.textSecondary)

                Spacer()

                Button(action: onPrepareAgenda) {
                    Text("Edit")
                        .font(Typography.caption1)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(items.prefix(3), id: \.self) { item in
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: "circle")
                                .font(.system(size: 6))
                                .foregroundStyle(Colors.textTertiary)
                                .padding(.top, 6)

                            Text(item)
                                .font(Typography.body)
                                .lineLimit(1)
                        }
                    }

                    if items.count > 3 {
                        Text("+\(items.count - 3) more")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Action Items Preview Section

private struct ActionItemsPreviewSection: View {
    let items: [ActionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label("Open Action Items", systemImage: "checklist")
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Colors.textSecondary)

                Spacer()

                Text("\(items.count)")
                    .font(Typography.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(items.contains { $0.isOverdue } ? Colors.error : Colors.warning)
                    .clipShape(Capsule())
            }

            Card {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(items.prefix(3)) { item in
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: item.isOverdue ? "exclamationmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(item.isOverdue ? Colors.error : Colors.textTertiary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(Typography.body)
                                    .lineLimit(1)

                                if let dueDate = item.formattedDueDate {
                                    Text(dueDate)
                                        .font(Typography.caption2)
                                        .foregroundStyle(item.isOverdue ? Colors.error : Colors.textTertiary)
                                }
                            }
                        }
                    }

                    if items.count > 3 {
                        Text("+\(items.count - 3) more")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Meeting History Section

private struct MeetingHistorySection: View {
    let pastMeetings: [Meeting]
    let streak: Int

    private var lastMeeting: Meeting? {
        pastMeetings.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Meeting History", systemImage: "clock.arrow.circlepath")
                .font(Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Colors.textSecondary)

            Card {
                HStack(spacing: Spacing.lg) {
                    // Last meeting
                    if let last = lastMeeting {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Last Meeting")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textTertiary)

                            HStack(spacing: Spacing.xxs) {
                                Text(last.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(Typography.body)

                                if let sentiment = last.meetingSentimentValue {
                                    Text(sentiment.emoji)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Streak
                    if streak > 0 {
                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            Text("Streak")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textTertiary)

                            HStack(spacing: Spacing.xxs) {
                                Text("\(streak)")
                                    .font(Typography.headline)
                                    .foregroundStyle(streak >= 4 ? Colors.success : Colors.textPrimary)

                                Image(systemName: "flame.fill")
                                    .foregroundStyle(streak >= 4 ? Colors.warning : Colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Completed Meeting Content

private struct CompletedMeetingContent: View {
    let meeting: Meeting

    var body: some View {
        VStack(spacing: Spacing.sectionSpacing) {
            // Sentiments
            if meeting.weekSentiment != nil || meeting.meetingSentiment != nil {
                SentimentsCard(meeting: meeting)
            }

            // Notes
            if !meeting.notes.isEmpty {
                NotesCard(notes: meeting.notes)
            }

            // What went well
            if !meeting.wentWell.isEmpty {
                FeedbackCard(
                    title: "What Went Well",
                    icon: "hand.thumbsup.fill",
                    iconColor: Colors.success,
                    items: meeting.wentWell
                )
            }

            // What didn't go well
            if !meeting.didntGoWell.isEmpty {
                FeedbackCard(
                    title: "What Didn't Go Well",
                    icon: "hand.thumbsdown.fill",
                    iconColor: Colors.warning,
                    items: meeting.didntGoWell
                )
            }

            // Blockers
            if !meeting.blockers.isEmpty {
                FeedbackCard(
                    title: "Blockers",
                    icon: "exclamationmark.octagon.fill",
                    iconColor: Colors.error,
                    items: meeting.blockers
                )
            }

            // Escalations
            if !meeting.escalations.isEmpty {
                FeedbackCard(
                    title: "Escalations",
                    icon: "arrow.up.circle.fill",
                    iconColor: Colors.info,
                    items: meeting.escalations
                )
            }
        }
    }
}

// MARK: - Sentiments Card

private struct SentimentsCard: View {
    let meeting: Meeting

    var body: some View {
        Card {
            HStack(spacing: Spacing.xl) {
                if let weekSentiment = meeting.weekSentimentValue {
                    VStack(spacing: Spacing.xs) {
                        Text(weekSentiment.emoji)
                            .font(.title)

                        Text("Week")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                if let meetingSentiment = meeting.meetingSentimentValue {
                    VStack(spacing: Spacing.xs) {
                        Text(meetingSentiment.emoji)
                            .font(.title)

                        Text("1:1")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Notes Card

private struct NotesCard: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Notes", systemImage: "note.text")
                .font(Typography.headline)

            Card {
                Text(notes)
                    .font(Typography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Feedback Card

private struct FeedbackCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: icon)
                .font(Typography.headline)
                .foregroundStyle(iconColor)

            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("•")
                                .foregroundStyle(iconColor)

                            Text(item)
                                .font(Typography.body)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Reschedule Meeting Sheet

struct RescheduleMeetingSheet: View {
    let meeting: Meeting

    @Environment(\.dismiss) private var dismiss
    @State private var newDate: Date

    init(meeting: Meeting) {
        self.meeting = meeting
        _newDate = State(initialValue: meeting.date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "New Date & Time",
                        selection: $newDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }

                Section {
                    Text("Original: \(meeting.date.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(Colors.textSecondary)
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        rescheduleMeeting()
                    }
                    .fontWeight(.semibold)
                    .disabled(newDate == meeting.date)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func rescheduleMeeting() {
        Task {
            if !AppSettings.shared.isDemoMode {
                if let sdMeeting = try? DataManager.shared.fetchMeeting(by: meeting.id) {
                    sdMeeting.date = newDate
                    try? DataManager.shared.save()
                }
            }

            Theme.successHaptic()
            dismiss()
        }
    }
}

// MARK: - Edit Recurrence Sheet

struct EditRecurrenceSheet: View {
    let meeting: Meeting

    @Environment(\.dismiss) private var dismiss
    @State private var frequency: RecurrenceRule.Frequency
    @State private var interval: Int
    @State private var selectedWeekday: RecurrenceRule.Weekday?

    init(meeting: Meeting) {
        self.meeting = meeting
        let recurrence = meeting.recurrence ?? RecurrenceRule(frequency: .weekly, interval: 1)
        _frequency = State(initialValue: recurrence.frequency)
        _interval = State(initialValue: recurrence.interval)
        _selectedWeekday = State(initialValue: recurrence.weekday)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    Picker("Repeat", selection: $frequency) {
                        ForEach(RecurrenceRule.Frequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)

                    Stepper("Every \(interval) \(frequency.displayName.lowercased())\(interval > 1 ? "s" : "")", value: $interval, in: 1...12)
                }

                if frequency == .weekly {
                    Section("Day of Week") {
                        WeekdayPicker(selectedDay: $selectedWeekday)
                    }
                }
            }
            .navigationTitle("Edit Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecurrence()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveRecurrence() {
        let newRecurrence = RecurrenceRule(
            frequency: frequency,
            interval: interval,
            weekday: selectedWeekday
        )

        Task {
            if !AppSettings.shared.isDemoMode {
                if let sdMeeting = try? DataManager.shared.fetchMeeting(by: meeting.id) {
                    sdMeeting.recurrence = newRecurrence
                    try? DataManager.shared.save()
                }
            }

            Theme.successHaptic()
            dismiss()
        }
    }
}

// MARK: - Weekday Picker

private struct WeekdayPicker: View {
    @Binding var selectedDay: RecurrenceRule.Weekday?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(RecurrenceRule.Weekday.allCases, id: \.self) { day in
                Button {
                    if selectedDay == day {
                        selectedDay = nil
                    } else {
                        selectedDay = day
                    }
                } label: {
                    Text(day.shortName)
                        .font(Typography.caption1)
                        .fontWeight(.medium)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selectedDay == day ? Color.accentColor : Colors.backgroundSecondary)
                        )
                        .foregroundStyle(selectedDay == day ? .white : Colors.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Meeting Detail - Completed") {
    let completedMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(-86400 * 7),
        status: .completed,
        notes: "Great discussion about Q4 priorities.",
        wentWell: ["Completed API migration", "Got positive feedback"],
        didntGoWell: ["Missed documentation deadline"],
        weekSentiment: 4,
        meetingSentiment: 5
    )
    return NavigationStack {
        MeetingDetailView(meeting: completedMeeting)
    }
}

#Preview("Meeting Detail - Scheduled") {
    let scheduledMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 2)
    )
    return NavigationStack {
        MeetingDetailView(meeting: scheduledMeeting)
    }
}
