import SwiftUI
import SwiftData

/// List of all career goals
struct GoalsListView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showingAddGoal = false
    @State private var showingUpgrade = false
    @State private var selectedFilter: GoalFilter = .active

    private var isDemoMode: Bool { AppSettings.shared.isDemoMode }

    var body: some View {
        List {
            // Filter section
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(GoalFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Content section
            if viewModel.filteredGoals(for: selectedFilter).isEmpty {
                Section {
                    EmptyStateForGoalFilter(filter: selectedFilter, onAdd: {
                        if AppSettings.shared.canAddMoreGoals {
                            showingAddGoal = true
                        } else {
                            showingUpgrade = true
                        }
                    })
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            } else {
                Section {
                    ForEach(viewModel.filteredGoals(for: selectedFilter)) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalListRow(goal: goal)
                        }
                    }
                    .onDelete { indexSet in
                        Task { await viewModel.deleteGoals(at: indexSet, filter: selectedFilter) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Career Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    if AppSettings.shared.canAddMoreGoals {
                        showingAddGoal = true
                    } else {
                        showingUpgrade = true
                    }
                }) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add goal")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView { goal in
                Task { await viewModel.addGoal(goal) }
            }
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView()
        }
        .refreshable {
            await viewModel.loadGoals()
        }
        .task {
            await viewModel.loadGoals()
        }
        .onChange(of: isDemoMode) { _, _ in
            // Reload when demo mode changes
            Task {
                await viewModel.loadGoals()
            }
        }
        .onChange(of: selectedFilter) { _, newValue in
            let count = viewModel.filteredGoals(for: newValue).count
            let message = "\(count) \(newValue.displayName.lowercased()) goal\(count == 1 ? "" : "s")"
            UIAccessibility.post(notification: .announcement, argument: message)
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

    private var context: ModelContext { DataManager.shared.context }
    private var sdGoals: [UUID: SDCareerGoal] = [:]

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
            updateCachedCount()
            isLoading = false
            return
        }

        do {
            let fetchedGoals = try DataManager.shared.fetchCareerGoals()
            goals = fetchedGoals.map { $0.toCareerGoal() }
            sdGoals = Dictionary(uniqueKeysWithValues: fetchedGoals.map { ($0.id, $0) })
            updateCachedCount()
        } catch {
            goals = []
        }
        isLoading = false
    }

    private func updateCachedCount() {
        // Cache active goal count for premium limit checking
        AppSettings.shared.cachedGoalCount = goals.filter { $0.isActive }.count
    }

    func addGoal(_ goal: CareerGoal) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            goals.insert(goal, at: 0)
            updateCachedCount()
            return
        }

        do {
            let sdGoal = SDCareerGoal(
                id: goal.id,
                title: goal.title,
                goalDescription: goal.goalDescription,
                category: goal.category,
                targetDate: goal.targetDate,
                status: goal.status,
                priority: goal.priority,
                successMetrics: goal.successMetrics,
                trackingMethod: goal.trackingMethod,
                progress: goal.progress,
                skills: goal.skills,
                notes: goal.notes,
                createdAt: goal.createdAt,
                updatedAt: goal.updatedAt
            )
            context.insert(sdGoal)
            try DataManager.shared.save()

            sdGoals[goal.id] = sdGoal
            goals.insert(goal, at: 0)
            updateCachedCount()
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

            if let sdGoal = sdGoals[goal.id] {
                context.delete(sdGoal)
                do {
                    try DataManager.shared.save()
                    sdGoals.removeValue(forKey: goal.id)
                    goals.removeAll { $0.id == goal.id }
                } catch {}
            }
        }
        updateCachedCount()
    }
}

// MARK: - Preview

#Preview("Goals List") {
    NavigationStack {
        GoalsListView()
    }
}
