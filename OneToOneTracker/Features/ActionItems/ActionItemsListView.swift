import SwiftUI

/// List view for all action items with filtering
struct ActionItemsListView: View {
    @StateObject private var viewModel = ActionItemsViewModel()
    @State private var showingAddItem = false
    @State private var selectedFilter: ActionItemFilter = .open

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ActionItemFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // List
            if viewModel.filteredItems(for: selectedFilter).isEmpty {
                EmptyStateForFilter(filter: selectedFilter)
            } else {
                List {
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
                .listStyle(.plain)
            }
        }
        .navigationTitle("Action Items")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
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
