import SwiftUI

/// View for conducting an active 1:1 meeting
struct ActiveMeetingView: View {
    @StateObject private var viewModel: ActiveMeetingViewModel
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var showingUpgrade = false
    @State private var showingExport = false
    @State private var showingSmartNotes = false
    @State private var showingImproveAllPreview = false
    @State private var batchPreview: BatchImprovementPreview?
    @State private var isImprovingAll = false
    @State private var showDemoExitPrompt = false
    @State private var showingErrorAlert = false

    var managerName: String = ""

    private var canAccessWeeklyGoals: Bool {
        AppSettings.shared.canAccessWeeklyGoals
    }

    private var canAccessAI: Bool {
        AppSettings.shared.canAccessAI
    }

    private var isCloudKitAvailable: Bool {
        // With SwiftData local-first storage, data is always available
        dataManager.isCloudKitAvailable || !dataManager.isUsingCloudKit || AppSettings.shared.isDemoMode
    }

    init(meeting: Meeting) {
        self._viewModel = StateObject(wrappedValue: ActiveMeetingViewModel(meeting: meeting))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // iCloud warning banner
                if !isCloudKitAvailable {
                    iCloudWarningBanner
                }

                // Timer
                MeetingTimer(startTime: viewModel.startTime)

                // Agenda checklist
                AgendaChecklistSection(viewModel: viewModel)

                // Weekly Goals & Metrics (Premium feature)
                if canAccessWeeklyGoals {
                    // This Week's Goals (optional, auto-populated from previous meeting)
                    FeedbackListSection(
                        title: "This Week's Goals",
                        icon: "list.clipboard.fill",
                        iconColor: .blue,
                        items: $viewModel.thisWeekGoals,
                        placeholder: "Add a goal for this week...",
                        sectionType: .thisWeekGoals
                    )

                    // Progress Updates (optional)
                    FeedbackListSection(
                        title: "Progress Updates",
                        icon: "chart.bar.fill",
                        iconColor: .purple,
                        items: $viewModel.thisWeekProgress,
                        placeholder: "Add a progress update...",
                        sectionType: .thisWeekProgress
                    )

                    // Key Metrics (optional, carries over between meetings)
                    FeedbackListSection(
                        title: "Key Metrics",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .orange,
                        items: $viewModel.keyMetrics,
                        placeholder: "Add a metric you're tracking...",
                        sectionType: .keyMetrics
                    )

                    // Next Week's Goals (optional, carries to next meeting)
                    FeedbackListSection(
                        title: "Next Week's Goals",
                        icon: "arrow.right.circle.fill",
                        iconColor: .teal,
                        items: $viewModel.nextWeekGoals,
                        placeholder: "Add a goal for next week...",
                        sectionType: .nextWeekGoals
                    )
                } else {
                    PremiumLockedSection(feature: .weeklyGoalsMetrics) {
                        showingUpgrade = true
                    }
                }

                // Notes
                NotesSection(notes: $viewModel.notes)

                // What went well
                FeedbackListSection(
                    title: "What Went Well",
                    icon: "hand.thumbsup.fill",
                    iconColor: Colors.success,
                    items: $viewModel.wentWell,
                    placeholder: "Add a win...",
                    sectionType: .wentWell
                )

                // What didn't go well
                FeedbackListSection(
                    title: "What Didn't Go Well",
                    icon: "hand.thumbsdown.fill",
                    iconColor: Colors.warning,
                    items: $viewModel.didntGoWell,
                    placeholder: "Add a challenge...",
                    sectionType: .didntGoWell
                )

                // Blockers
                FeedbackListSection(
                    title: "Blockers",
                    icon: "exclamationmark.octagon.fill",
                    iconColor: Colors.error,
                    items: $viewModel.blockers,
                    placeholder: "Add a blocker...",
                    sectionType: .blockers
                )

                // Escalations
                FeedbackListSection(
                    title: "Escalations for Manager",
                    icon: "arrow.up.circle.fill",
                    iconColor: Colors.info,
                    items: $viewModel.escalations,
                    placeholder: "Add an escalation...",
                    sectionType: .escalations
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
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    // Smart Notes button (AI)
                    if canAccessAI {
                        Button {
                            showingSmartNotes = true
                        } label: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .accessibilityLabel("Smart Notes")
                        }
                    }

                    // Improve All menu (AI)
                    if canAccessAI {
                        Menu {
                            ForEach(NoteImprovementType.allCases) { type in
                                Button {
                                    Task { await improveAllSections(type: type) }
                                } label: {
                                    Label(type.displayName, systemImage: type.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "sparkles")
                                .accessibilityLabel("Improve all notes")
                        }
                        .disabled(isImprovingAll)
                    }

                    // Export button
                    Button {
                        showingExport = true
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .accessibilityLabel("Export meeting")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportMeetingView(
                meeting: viewModel.meeting,
                managerName: managerName.isEmpty ? "Person" : managerName,
                agendaItems: viewModel.agendaItems,
                actionItems: viewModel.newActionItems
            )
        }
        .confirmationDialog(
            "End Meeting",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("Complete Meeting") {
                if AppSettings.shared.isDemoMode {
                    showDemoExitPrompt = true
                } else {
                    Task {
                        await viewModel.completeMeeting()
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will save all notes and mark the meeting as complete.")
        }
        .alert("Exit Demo Mode?", isPresented: $showDemoExitPrompt) {
            Button("Stay in Demo", role: .cancel) {
                Task {
                    await viewModel.completeMeeting()
                    dismiss()
                }
            }
            Button("Exit Demo Mode") {
                AppSettings.shared.isDemoMode = false
                Task {
                    await viewModel.completeMeeting()
                    dismiss()
                }
            }
        } message: {
            Text("You're saving real meeting data. Would you like to exit demo mode to save your notes permanently?")
        }
        .alert("Unable to Save", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred while saving your meeting. Please check your iCloud settings.")
        }
        .onChange(of: viewModel.error != nil) { _, hasError in
            if hasError {
                showingErrorAlert = true
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView()
        }
        .sheet(isPresented: $showingSmartNotes) {
            SmartNotesSheet { result, manualAssignments in
                applySmartNotesResult(result, manualAssignments: manualAssignments)
            }
        }
        .sheet(isPresented: $showingImproveAllPreview) {
            if let preview = batchPreview {
                BatchImprovementPreviewSheet(
                    preview: preview,
                    onApply: {
                        applyBatchImprovements(preview)
                    },
                    onCancel: { }
                )
            }
        }
    }

    // MARK: - AI Helper Functions

    private func improveAllSections(type: NoteImprovementType) async {
        isImprovingAll = true

        var improvements: [NoteImprovementPreview] = []

        // Improve each non-empty section
        let sectionsToImprove: [(MeetingSectionType, [String])] = [
            (.wentWell, viewModel.wentWell),
            (.didntGoWell, viewModel.didntGoWell),
            (.blockers, viewModel.blockers),
            (.escalations, viewModel.escalations),
            (.thisWeekGoals, viewModel.thisWeekGoals),
            (.thisWeekProgress, viewModel.thisWeekProgress),
            (.keyMetrics, viewModel.keyMetrics),
            (.nextWeekGoals, viewModel.nextWeekGoals)
        ]

        for (section, items) in sectionsToImprove where !items.isEmpty {
            let improved = await AIManager.shared.improveItems(items, type: type, section: section)
            improvements.append(NoteImprovementPreview(
                sectionType: section,
                improvementType: type,
                originalContent: items,
                improvedContent: improved
            ))
        }

        batchPreview = BatchImprovementPreview(improvements: improvements, improvementType: type)
        isImprovingAll = false
        showingImproveAllPreview = true
    }

    private func applyBatchImprovements(_ preview: BatchImprovementPreview) {
        for improvement in preview.improvements where improvement.hasChanges {
            switch improvement.sectionType {
            case .wentWell:
                viewModel.wentWell = improvement.improvedContent
            case .didntGoWell:
                viewModel.didntGoWell = improvement.improvedContent
            case .blockers:
                viewModel.blockers = improvement.improvedContent
            case .escalations:
                viewModel.escalations = improvement.improvedContent
            case .thisWeekGoals:
                viewModel.thisWeekGoals = improvement.improvedContent
            case .thisWeekProgress:
                viewModel.thisWeekProgress = improvement.improvedContent
            case .keyMetrics:
                viewModel.keyMetrics = improvement.improvedContent
            case .nextWeekGoals:
                viewModel.nextWeekGoals = improvement.improvedContent
            case .notes:
                break // Notes handled separately
            }
        }
        Theme.successHaptic()
    }

    private func applySmartNotesResult(_ result: SmartNotesResult, manualAssignments: [String: MeetingSectionType]) {
        // Apply categorized items
        for (section, items) in result.categorizedItems {
            switch section {
            case .wentWell:
                viewModel.wentWell.append(contentsOf: items)
            case .didntGoWell:
                viewModel.didntGoWell.append(contentsOf: items)
            case .blockers:
                viewModel.blockers.append(contentsOf: items)
            case .escalations:
                viewModel.escalations.append(contentsOf: items)
            case .thisWeekGoals:
                viewModel.thisWeekGoals.append(contentsOf: items)
            case .thisWeekProgress:
                viewModel.thisWeekProgress.append(contentsOf: items)
            case .keyMetrics:
                viewModel.keyMetrics.append(contentsOf: items)
            case .nextWeekGoals:
                viewModel.nextWeekGoals.append(contentsOf: items)
            case .notes:
                if !items.isEmpty {
                    viewModel.notes += (viewModel.notes.isEmpty ? "" : "\n") + items.joined(separator: "\n")
                }
            }
        }

        // Apply manual assignments
        for (item, section) in manualAssignments {
            switch section {
            case .wentWell:
                viewModel.wentWell.append(item)
            case .didntGoWell:
                viewModel.didntGoWell.append(item)
            case .blockers:
                viewModel.blockers.append(item)
            case .escalations:
                viewModel.escalations.append(item)
            case .thisWeekGoals:
                viewModel.thisWeekGoals.append(item)
            case .thisWeekProgress:
                viewModel.thisWeekProgress.append(item)
            case .keyMetrics:
                viewModel.keyMetrics.append(item)
            case .nextWeekGoals:
                viewModel.nextWeekGoals.append(item)
            case .notes:
                viewModel.notes += (viewModel.notes.isEmpty ? "" : "\n") + item
            }
        }

        Theme.successHaptic()
    }

    // MARK: - iCloud Warning Banner

    private var iCloudWarningBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.icloud")
                .foregroundStyle(Colors.warning)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("iCloud Not Available")
                    .font(Typography.subheadline.weight(.semibold))
                Text("Sign in to iCloud in Settings to save your meetings.")
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)
            }

            Spacer()

            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(Typography.caption1.weight(.medium))
        }
        .padding(Spacing.md)
        .background(Colors.warning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
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
    var sectionType: MeetingSectionType? = nil

    @State private var newItem = ""
    @State private var isProcessing = false
    @State private var showingPreview = false
    @State private var preview: NoteImprovementPreview?
    @State private var showingUpgrade = false

    private var canAccessAI: Bool {
        AppSettings.shared.canAccessAI
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with optional AI button
            HStack {
                Label(title, systemImage: icon)
                    .font(Typography.headline)
                    .foregroundStyle(iconColor)

                Spacer()

                // AI Improve button (only if sectionType provided and items not empty)
                if let sectionType = sectionType, !items.wrappedValue.isEmpty {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if canAccessAI {
                        Menu {
                            ForEach(NoteImprovementType.allCases) { type in
                                Button {
                                    Task { await improveSection(type: type, section: sectionType) }
                                } label: {
                                    Label(type.displayName, systemImage: type.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                        .accessibilityLabel("Improve with AI")
                    } else {
                        Button {
                            showingUpgrade = true
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                PremiumBadge()
                            }
                        }
                    }
                }
            }

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
        .sheet(isPresented: $showingPreview) {
            if let preview = preview {
                ImprovementPreviewSheet(
                    preview: preview,
                    onApply: {
                        items.wrappedValue = preview.improvedContent
                        Theme.successHaptic()
                    },
                    onCancel: { }
                )
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradePromptSheet(feature: .aiSuggestions) {
                showingUpgrade = false
            }
        }
    }

    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        items.wrappedValue.append(newItem)
        newItem = ""
        Theme.lightHaptic()
    }

    private func improveSection(type: NoteImprovementType, section: MeetingSectionType) async {
        isProcessing = true

        let improved = await AIManager.shared.improveItems(
            items.wrappedValue,
            type: type,
            section: section
        )

        preview = NoteImprovementPreview(
            sectionType: section,
            improvementType: type,
            originalContent: items.wrappedValue,
            improvedContent: improved
        )

        isProcessing = false
        showingPreview = true
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
