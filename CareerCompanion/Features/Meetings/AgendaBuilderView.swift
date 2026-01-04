import SwiftUI
import SwiftData

/// View for building and editing meeting agenda
struct AgendaBuilderView: View {
    let meeting: Meeting

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AgendaBuilderViewModel
    @StateObject private var aiManager = AIManager.shared
    @State private var showingShareSheet = false
    @State private var showingAddItem = false
    @State private var newItemTitle = ""
    @State private var aiSuggestions: [String] = []
    @State private var isLoadingAI = false
    @FocusState private var isNewItemFocused: Bool

    // Prep section input fields
    @State private var newGoal = ""
    @State private var newProgress = ""
    @State private var newMetric = ""

    // AI improvement state
    @State private var isImprovingSection = false
    @State private var isImprovingAll = false
    @State private var showingImprovePreview = false
    @State private var showingBatchPreview = false
    @State private var showingUpgrade = false
    @State private var improvementPreview: NoteImprovementPreview?
    @State private var batchPreview: BatchImprovementPreview?
    @State private var currentImprovingSection: MeetingSectionType?

    private var canAccessAI: Bool {
        AppSettings.shared.canAccessAI
    }

    init(meeting: Meeting) {
        self.meeting = meeting
        self._viewModel = StateObject(wrappedValue: AgendaBuilderViewModel(meeting: meeting))
    }

    var body: some View {
        List {
            // Agenda items (at top)
            Section {
                ForEach(viewModel.agendaItems) { item in
                    AgendaItemRow(
                        item: item,
                        onUpdate: { updated in
                            Task {
                                await viewModel.updateItem(updated)
                            }
                        }
                    )
                }
                .onMove { from, to in
                    viewModel.moveItems(from: from, to: to)
                }
                .onDelete { indexSet in
                    Task {
                        await viewModel.deleteItems(at: indexSet)
                    }
                }

                // Add new item inline
                HStack {
                    TextField("Add agenda item...", text: $newItemTitle)
                        .focused($isNewItemFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addNewItem()
                        }

                    if !newItemTitle.isEmpty {
                        Button(action: addNewItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } header: {
                Label("Agenda", systemImage: "list.bullet")
            }

            // Quick add templates
            Section {
                ForEach(AgendaTemplate.allCases) { template in
                    Button(action: {
                        Task {
                            await viewModel.addTemplate(template)
                        }
                    }) {
                        Label(template.title, systemImage: template.icon)
                    }
                }
            } header: {
                Text("Quick Add")
            }

            // AI Suggestions section
            if aiManager.isAvailable && aiManager.isEnabled {
                AISuggestionsSection(
                    suggestions: aiSuggestions,
                    isLoading: isLoadingAI,
                    onRefresh: loadAISuggestions,
                    onAdd: { suggestion in
                        Task {
                            await viewModel.addItem(title: suggestion)
                            // Remove used suggestion
                            aiSuggestions.removeAll { $0 == suggestion }
                        }
                    }
                )
            }

            // Meeting Goals Section
            Section {
                TextField("What do you want to accomplish in this meeting?", text: $viewModel.meetingNotes, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: viewModel.meetingNotes) { _, newValue in
                        viewModel.updateMeetingNotes(newValue)
                    }
            } header: {
                Label("Meeting Goals", systemImage: "target")
            }

            // This Week's Progress Section
            Section {
                ForEach(Array(viewModel.thisWeekProgress.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Colors.success)
                            .font(.caption)
                        Text(item)
                            .font(Typography.body)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeProgress(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                HStack {
                    TextField("Add progress item...", text: $newProgress)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.addProgress(newProgress)
                            newProgress = ""
                        }

                    if !newProgress.isEmpty {
                        Button {
                            viewModel.addProgress(newProgress)
                            newProgress = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } header: {
                HStack {
                    Label("This Week's Progress", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    if !viewModel.thisWeekProgress.isEmpty {
                        if currentImprovingSection == .thisWeekProgress {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if canAccessAI {
                            Menu {
                                ForEach(NoteImprovementType.allCases) { type in
                                    Button {
                                        Task { await improveSection(type: type, section: .thisWeekProgress) }
                                    } label: {
                                        Label(type.displayName, systemImage: type.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
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
            } footer: {
                Text("Updates and accomplishments to share")
            }

            // Key Metrics Section
            Section {
                ForEach(Array(viewModel.keyMetrics.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(Color.accentColor)
                            .font(.caption)
                        Text(item)
                            .font(Typography.body)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeMetric(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                HStack {
                    TextField("Add metric...", text: $newMetric)
                        .submitLabel(.done)
                        .onSubmit {
                            viewModel.addMetric(newMetric)
                            newMetric = ""
                        }

                    if !newMetric.isEmpty {
                        Button {
                            viewModel.addMetric(newMetric)
                            newMetric = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } header: {
                HStack {
                    Label("Key Metrics", systemImage: "chart.bar")
                    Spacer()
                    if !viewModel.keyMetrics.isEmpty {
                        if currentImprovingSection == .keyMetrics {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if canAccessAI {
                            Menu {
                                ForEach(NoteImprovementType.allCases) { type in
                                    Button {
                                        Task { await improveSection(type: type, section: .keyMetrics) }
                                    } label: {
                                        Label(type.displayName, systemImage: type.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
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
            } footer: {
                Text("Numbers and data points to discuss")
            }

            // Carried over action items
            if !viewModel.carriedOverItems.isEmpty {
                Section {
                    ForEach(viewModel.carriedOverItems) { item in
                        CarriedOverItemRow(item: item)
                    }
                } header: {
                    Label("Action Items to Review", systemImage: "arrow.uturn.forward")
                } footer: {
                    Text("These items will be automatically added to your agenda")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Prepare for Meeting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    // Improve All menu (AI)
                    if canAccessAI && (!viewModel.thisWeekProgress.isEmpty || !viewModel.keyMetrics.isEmpty) {
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

                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Share agenda")
                    }
                    .disabled(viewModel.agendaItems.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareAgendaView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingImprovePreview) {
            if let preview = improvementPreview {
                ImprovementPreviewSheet(
                    preview: preview,
                    onApply: {
                        applyImprovement(preview)
                    },
                    onCancel: { }
                )
            }
        }
        .sheet(isPresented: $showingBatchPreview) {
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
        .sheet(isPresented: $showingUpgrade) {
            UpgradePromptSheet(feature: .aiSuggestions) {
                showingUpgrade = false
            }
        }
        .task {
            await viewModel.loadData()
            if aiManager.isAvailable && aiManager.isEnabled {
                await loadAISuggestions()
            }
        }
    }

    private func addNewItem() {
        guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            await viewModel.addItem(title: newItemTitle)
            newItemTitle = ""
        }
    }

    private func loadAISuggestions() async {
        isLoadingAI = true

        // Fetch previous meetings and action items for context
        var previousMeetings: [Meeting] = []
        var openActionItems: [ActionItem] = []

        if AppSettings.shared.isDemoMode {
            previousMeetings = DemoDataProvider.meetings.filter { $0.status == .completed }
            openActionItems = DemoDataProvider.actionItems.filter { $0.status != .completed }
        } else {
            // Fetch previous meetings for this manager
            let managerID = meeting.managerID
            let completedStatus = MeetingStatus.completed.rawValue
            let meetingPredicate = #Predicate<SDMeeting> { $0.manager?.id == managerID && $0.statusRaw == completedStatus }
            if let fetchedMeetings = try? DataManager.shared.fetchMeetings(predicate: meetingPredicate) {
                previousMeetings = fetchedMeetings.map { $0.toMeeting() }
            }

            // Fetch open action items
            let completedActionStatus = ActionItemStatus.completed.rawValue
            let actionItemPredicate = #Predicate<SDActionItem> { $0.statusRaw != completedActionStatus }
            if let fetchedItems = try? DataManager.shared.fetchActionItems(predicate: actionItemPredicate) {
                openActionItems = fetchedItems.map { $0.toActionItem() }
            }
        }

        aiSuggestions = await aiManager.suggestAgendaItems(
            previousMeetings: previousMeetings,
            openActionItems: openActionItems,
            managerName: "" // We could fetch manager name here
        )

        isLoadingAI = false
    }

    // MARK: - AI Improvement Functions

    private func improveSection(type: NoteImprovementType, section: MeetingSectionType) async {
        currentImprovingSection = section

        let items: [String]
        switch section {
        case .thisWeekProgress:
            items = viewModel.thisWeekProgress
        case .keyMetrics:
            items = viewModel.keyMetrics
        default:
            currentImprovingSection = nil
            return
        }

        guard !items.isEmpty else {
            currentImprovingSection = nil
            return
        }

        let improved = await AIManager.shared.improveItems(items, type: type, section: section)

        improvementPreview = NoteImprovementPreview(
            sectionType: section,
            improvementType: type,
            originalContent: items,
            improvedContent: improved
        )

        currentImprovingSection = nil
        showingImprovePreview = true
    }

    private func improveAllSections(type: NoteImprovementType) async {
        isImprovingAll = true

        var improvements: [NoteImprovementPreview] = []

        let sectionsToImprove: [(MeetingSectionType, [String])] = [
            (.thisWeekProgress, viewModel.thisWeekProgress),
            (.keyMetrics, viewModel.keyMetrics)
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
        showingBatchPreview = true
    }

    private func applyImprovement(_ preview: NoteImprovementPreview) {
        switch preview.sectionType {
        case .thisWeekProgress:
            viewModel.thisWeekProgress = preview.improvedContent
        case .keyMetrics:
            viewModel.keyMetrics = preview.improvedContent
        default:
            break
        }
        Theme.successHaptic()
    }

    private func applyBatchImprovements(_ preview: BatchImprovementPreview) {
        for improvement in preview.improvements where improvement.hasChanges {
            switch improvement.sectionType {
            case .thisWeekProgress:
                viewModel.thisWeekProgress = improvement.improvedContent
            case .keyMetrics:
                viewModel.keyMetrics = improvement.improvedContent
            default:
                break
            }
        }
        Theme.successHaptic()
    }
}

// MARK: - AI Suggestions Section

private struct AISuggestionsSection: View {
    let suggestions: [String]
    let isLoading: Bool
    let onRefresh: () async -> Void
    let onAdd: (String) -> Void

    var body: some View {
        Section {
            if isLoading {
                HStack {
                    ProgressView()
                        .padding(.trailing, Spacing.sm)
                    Text("Getting suggestions...")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)
                }
            } else if suggestions.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Colors.textTertiary)
                    Text("No suggestions available")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)

                    Spacer()

                    Button {
                        Task {
                            await onRefresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            } else {
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.accentColor)
                            .font(.caption)

                        Text(suggestion)
                            .font(Typography.body)

                        Spacer()

                        Button {
                            onAdd(suggestion)
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
        } header: {
            HStack {
                Label("AI Suggestions", systemImage: "sparkles")
                Spacer()
                if !isLoading && !suggestions.isEmpty {
                    Button {
                        Task {
                            await onRefresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        } footer: {
            Text("Suggestions based on your previous meetings and open action items")
        }
    }
}

// MARK: - Agenda Item Row

private struct AgendaItemRow: View {
    let item: AgendaItem
    let onUpdate: (AgendaItem) -> Void

    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedNotes: String

    init(item: AgendaItem, onUpdate: @escaping (AgendaItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        self._editedTitle = State(initialValue: item.title)
        self._editedNotes = State(initialValue: item.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Colors.textTertiary)
                    .accessibilityHidden(true)

                if isEditing {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        TextField("Agenda item", text: $editedTitle)
                            .font(Typography.body)

                        TextField("Add notes...", text: $editedNotes, axis: .vertical)
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                            .lineLimit(3...6)
                    }

                    Button("Done") {
                        saveEdit()
                    }
                    .foregroundStyle(Color.accentColor)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.title)
                            .font(Typography.body)

                        if !item.notes.isEmpty {
                            Text(item.notes)
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Colors.textTertiary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                isEditing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap to edit agenda item")
    }

    private func saveEdit() {
        var updated = item
        updated.title = editedTitle
        updated.notes = editedNotes
        onUpdate(updated)
        isEditing = false
    }
}

// MARK: - Carried Over Item Row

private struct CarriedOverItemRow: View {
    let item: ActionItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.uturn.forward.circle")
                .foregroundStyle(Colors.warning)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)

                if let date = item.formattedDueDate {
                    Text("Due: \(date)")
                        .font(Typography.caption1)
                        .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Agenda Templates

enum AgendaTemplate: String, CaseIterable, Identifiable {
    case weekHighlights
    case challenges
    case blockers
    case careerGrowth
    case feedback
    case nextSteps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekHighlights: return "Week highlights"
        case .challenges: return "Challenges faced"
        case .blockers: return "Blockers & escalations"
        case .careerGrowth: return "Career growth discussion"
        case .feedback: return "Feedback"
        case .nextSteps: return "Next steps"
        }
    }

    var icon: String {
        switch self {
        case .weekHighlights: return "star"
        case .challenges: return "exclamationmark.triangle"
        case .blockers: return "hand.raised"
        case .careerGrowth: return "chart.line.uptrend.xyaxis"
        case .feedback: return "bubble.left.and.bubble.right"
        case .nextSteps: return "arrow.right.circle"
        }
    }
}

// MARK: - Preview

#Preview("Agenda Builder") {
    let previewMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 2)
    )
    return NavigationStack {
        AgendaBuilderView(meeting: previewMeeting)
    }
}
