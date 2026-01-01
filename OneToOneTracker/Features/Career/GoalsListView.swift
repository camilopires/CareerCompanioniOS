import SwiftUI

/// List of all career goals
struct GoalsListView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showingAddGoal = false
    @State private var selectedFilter: GoalFilter = .active

    var body: some View {
        VStack(spacing: 0) {
            // Filter
            Picker("Filter", selection: $selectedFilter) {
                ForEach(GoalFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // List
            if viewModel.filteredGoals(for: selectedFilter).isEmpty {
                EmptyStateForGoalFilter(filter: selectedFilter, onAdd: { showingAddGoal = true })
            } else {
                List {
                    ForEach(viewModel.filteredGoals(for: selectedFilter)) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalListRow(goal: goal)
                        }
                    }
                    .onDelete { indexSet in
                        Task { await viewModel.deleteGoals(at: indexSet, filter: selectedFilter) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Career Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddGoal = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView { goal in
                Task { await viewModel.addGoal(goal) }
            }
        }
        .task {
            await viewModel.loadGoals()
        }
    }
}

// MARK: - Filter

enum GoalFilter: String, CaseIterable, Identifiable {
    case active
    case achieved
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .achieved: return "Achieved"
        case .all: return "All"
        }
    }
}

// MARK: - Goal Row

struct GoalListRow: View {
    let goal: CareerGoal

    var body: some View {
        HStack(spacing: Spacing.md) {
            GoalProgressRing(goal: goal)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(goal.title)
                    .font(Typography.body)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    Label(goal.category.displayName, systemImage: goal.category.icon)
                        .foregroundStyle(goal.category.color)

                    Label(goal.status.displayName, systemImage: goal.status.icon)
                        .foregroundStyle(goal.status.color)
                }
                .font(Typography.caption1)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Empty State

private struct EmptyStateForGoalFilter: View {
    let filter: GoalFilter
    let onAdd: () -> Void

    var body: some View {
        VStack {
            Spacer()

            switch filter {
            case .active:
                EmptyState(
                    icon: "star",
                    title: "No Active Goals",
                    message: "Set a career goal to start tracking your growth.",
                    actionTitle: "Add Goal",
                    action: onAdd
                )
            case .achieved:
                EmptyState(
                    icon: "trophy",
                    title: "No Achieved Goals Yet",
                    message: "Keep working on your goals to see them here."
                )
            case .all:
                EmptyState.noGoals
            }

            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: [CareerGoal] = []
    @Published var isLoading = false

    func filteredGoals(for filter: GoalFilter) -> [CareerGoal] {
        switch filter {
        case .active:
            return goals.filter { $0.isActive }.sorted { $0.priority == .primary && $1.priority != .primary }
        case .achieved:
            return goals.filter { $0.isAchieved }
        case .all:
            return goals
        }
    }

    func loadGoals() async {
        isLoading = true

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            goals = DemoDataProvider.careerGoals
            isLoading = false
            return
        }

        do {
            goals = try await CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)]
            )
        } catch {
            // Show empty state on error
            goals = []
        }
        isLoading = false
    }

    func addGoal(_ goal: CareerGoal) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            goals.insert(goal, at: 0)
            return
        }

        do {
            let saved = try await CloudKitManager.shared.save(goal)
            goals.insert(saved, at: 0)
        } catch {}
    }

    func deleteGoals(at offsets: IndexSet, filter: GoalFilter) async {
        let filtered = filteredGoals(for: filter)
        for index in offsets {
            let goal = filtered[index]

            // In demo mode, only update in-memory
            if AppSettings.shared.isDemoMode {
                goals.removeAll { $0.id == goal.id }
                continue
            }

            do {
                try await CloudKitManager.shared.delete(goal)
                goals.removeAll { $0.id == goal.id }
            } catch {}
        }
    }
}

// MARK: - Preview

#Preview("Goals List") {
    NavigationStack {
        GoalsListView()
    }
}
