import SwiftUI

/// Main career tracking home screen
struct CareerHomeView: View {
    @StateObject private var viewModel = CareerHomeViewModel()
    @State private var showingAddGoal = false
    @State private var showingAddAchievement = false
    @State private var showingReportBuilder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Progress overview
                    OverallProgressCard(viewModel: viewModel)

                    // Goals section
                    GoalsSummarySection(viewModel: viewModel, onAddGoal: { showingAddGoal = true })

                    // Achievements section
                    AchievementsSummarySection(viewModel: viewModel, onAddAchievement: { showingAddAchievement = true })

                    // Generate Report button
                    Button(action: { showingReportBuilder = true }) {
                        Label("Generate Performance Report", systemImage: "doc.text.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Colors.backgroundGrouped)
            .navigationTitle("Career")
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView { goal in
                    Task { await viewModel.addGoal(goal) }
                }
            }
            .sheet(isPresented: $showingAddAchievement) {
                AddAchievementView(goals: viewModel.goals) { achievement in
                    Task { await viewModel.addAchievement(achievement) }
                }
            }
            .sheet(isPresented: $showingReportBuilder) {
                ReportBuilderView(goals: viewModel.goals, achievements: viewModel.achievements)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Overall Progress Card

private struct OverallProgressCard: View {
    @ObservedObject var viewModel: CareerHomeViewModel

    var body: some View {
        Card(style: .elevated) {
            HStack(spacing: Spacing.xl) {
                ProgressRing(
                    progress: viewModel.overallProgress,
                    size: 80,
                    lineWidth: 10
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Overall Progress")
                        .font(Typography.headline)

                    HStack(spacing: Spacing.lg) {
                        StatBadge(value: viewModel.activeGoalsCount, label: "Active Goals", color: .accentColor)
                        StatBadge(value: viewModel.achievementsThisYear, label: "Achievements", color: Colors.success)
                    }
                }

                Spacer()
            }
        }
    }
}

private struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(value)")
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(Colors.textSecondary)
        }
    }
}

// MARK: - Goals Summary Section

private struct GoalsSummarySection: View {
    @ObservedObject var viewModel: CareerHomeViewModel
    let onAddGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Career Goals")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: GoalsListView()) {
                    Text("See All")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            if viewModel.goals.isEmpty {
                Card {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Colors.textTertiary)

                        Text("Set your first career goal")
                            .font(Typography.body)
                            .foregroundStyle(Colors.textSecondary)

                        Button("Add Goal", action: onAddGoal)
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(maxWidth: 200)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.goals.prefix(3)) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalSummaryRow(goal: goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct GoalSummaryRow: View {
    let goal: CareerGoal

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                GoalProgressRing(goal: goal)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(goal.title)
                        .font(Typography.body)
                        .foregroundStyle(Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.sm) {
                        Label(goal.category.displayName, systemImage: goal.category.icon)
                            .foregroundStyle(goal.category.color)

                        if let days = goal.daysUntilTarget, days > 0 {
                            Text("\(days) days left")
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                    .font(Typography.caption1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Colors.textTertiary)
            }
        }
    }
}

// MARK: - Achievements Summary Section

private struct AchievementsSummarySection: View {
    @ObservedObject var viewModel: CareerHomeViewModel
    let onAddAchievement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Achievements")
                    .font(Typography.headline)

                Spacer()

                Button(action: onAddAchievement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            if viewModel.achievements.isEmpty {
                CompactEmptyState(icon: "trophy", message: "No achievements recorded yet")
                    .background(Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.achievements.prefix(3)) { achievement in
                        NavigationLink(destination: AchievementDetailView(achievement: achievement)) {
                            AchievementSummaryRow(achievement: achievement)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AchievementSummaryRow: View {
    let achievement: Achievement

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(achievement.title)
                        .font(Typography.body)
                        .foregroundStyle(Colors.textPrimary)
                        .lineLimit(1)

                    Text(achievement.formattedDate)
                        .font(Typography.caption1)
                        .foregroundStyle(Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Colors.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Career Home") {
    CareerHomeView()
}
