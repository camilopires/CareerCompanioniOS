import SwiftUI

/// List view for all action items with filtering
struct ActionItemsListView: View {
    @StateObject private var viewModel = ActionItemsViewModel()
    @State private var showingAddItem = false
    @State private var selectedFilter: ActionItemFilter = .open

    private var isDemoMode: Bool { AppSettings.shared.isDemoMode }

    var body: some View {
        List {
            // Filter picker section
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ActionItemFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Content section
            if viewModel.filteredItems(for: selectedFilter).isEmpty {
                Section {
                    EmptyStateForFilter(filter: selectedFilter)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            } else {
                Section {
                    ForEach(viewModel.filteredItems(for: selectedFilter)) { item in
                        NavigationLink(destination: ActionItemDetailView(item: item)) {
                            ActionItemListRow(
                                item: item,
                                onComplete: {
                                    Task {
                                        await viewModel.toggleComplete(item)
                                    }
                                }
                            )
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteItems(at: indexSet, filter: selectedFilter)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Action Items")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add action item")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddActionItemView { item in
                Task {
                    await viewModel.addItem(item)
                }
            }
        }
        .refreshable {
            await viewModel.loadItems()
        }
        .task {
            await viewModel.loadItems()
        }
        .onChange(of: isDemoMode) { _, _ in
            // Reload when demo mode changes
            Task {
                await viewModel.loadItems()
            }
        }
        .onChange(of: selectedFilter) { _, newValue in
            let count = viewModel.filteredItems(for: newValue).count
            let message = "\(count) \(newValue.displayName.lowercased()) item\(count == 1 ? "" : "s")"
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

// MARK: - Filter

enum ActionItemFilter: String, CaseIterable, Identifiable {
    case open
    case completed
    case overdue
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .completed: return "Done"
        case .overdue: return "Overdue"
        case .all: return "All"
        }
    }
}

// MARK: - List Row

struct ActionItemListRow: View {
    let item: ActionItem
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Complete button
            Button(action: onComplete) {
                Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.status == .completed ? Colors.success : (item.isOverdue ? Colors.error : Colors.textTertiary))
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)
                    .strikethrough(item.status == .completed)
                    .foregroundStyle(item.status == .completed ? Colors.textSecondary : Colors.textPrimary)

                HStack(spacing: Spacing.sm) {
                    // Priority
                    if item.priority == .high {
                        Label("High", systemImage: item.priority.icon)
                            .foregroundStyle(item.priority.color)
                    }

                    // Due date
                    if let date = item.formattedDueDate {
                        Label(date, systemImage: "calendar")
                            .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                    }

                    // Owner
                    Label(item.owner.displayName, systemImage: item.owner.icon)
                        .foregroundStyle(Colors.textSecondary)
                }
                .font(Typography.caption1)
                .labelStyle(CompactLabelStyle())
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Empty State

private struct EmptyStateForFilter: View {
    let filter: ActionItemFilter

    var body: some View {
        switch filter {
        case .open:
            EmptyState.noActionItems
        case .completed:
            EmptyState(
                icon: "checkmark.circle",
                title: "No Completed Items",
                message: "Complete some action items to see them here."
            )
        case .overdue:
            EmptyState(
                icon: "clock.badge.checkmark",
                title: "Nothing Overdue",
                message: "Great job staying on top of your tasks!"
            )
        case .all:
            EmptyState.noActionItems
        }
    }
}

// MARK: - Preview

#Preview("Action Items List") {
    NavigationStack {
        ActionItemsListView()
    }
}
