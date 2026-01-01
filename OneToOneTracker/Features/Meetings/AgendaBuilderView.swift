import SwiftUI

/// View for building and editing meeting agenda
struct AgendaBuilderView: View {
    let meeting: Meeting

    @StateObject private var viewModel: AgendaBuilderViewModel
    @State private var showingShareSheet = false
    @State private var showingAddItem = false
    @State private var newItemTitle = ""
    @FocusState private var isNewItemFocused: Bool

    init(meeting: Meeting) {
        self.meeting = meeting
        self._viewModel = StateObject(wrappedValue: AgendaBuilderViewModel(meeting: meeting))
    }

    var body: some View {
        List {
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

            // Agenda items
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
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Prepare Agenda")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Share agenda")
                }
                .disabled(viewModel.agendaItems.isEmpty)
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareAgendaView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData()
        }
    }

    private func addNewItem() {
        guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            await viewModel.addItem(title: newItemTitle)
            newItemTitle = ""
        }
    }
}

// MARK: - Agenda Item Row

private struct AgendaItemRow: View {
    let item: AgendaItem
    let onUpdate: (AgendaItem) -> Void

    @State private var isEditing = false
    @State private var editedTitle: String

    init(item: AgendaItem, onUpdate: @escaping (AgendaItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        self._editedTitle = State(initialValue: item.title)
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Drag handle (implicit in edit mode)
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Colors.textTertiary)
                .accessibilityHidden(true)

            if isEditing {
                TextField("Agenda item", text: $editedTitle)
                    .onSubmit {
                        saveEdit()
                    }

                Button("Done") {
                    saveEdit()
                }
                .foregroundStyle(Color.accentColor)
            } else {
                Text(item.title)
                    .font(Typography.body)

                Spacer()

                Button(action: { isEditing = true }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit item")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func saveEdit() {
        var updated = item
        updated.title = editedTitle
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
    NavigationStack {
        AgendaBuilderView(meeting: Meeting.sample)
    }
}
