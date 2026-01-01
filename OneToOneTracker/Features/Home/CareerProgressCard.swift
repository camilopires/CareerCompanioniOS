import SwiftUI

/// Card showing career goals progress on the home screen
struct CareerProgressCard: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Career Goals")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: CareerHomeView()) {
                    Text("View All")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Content
            if viewModel.activeGoals.isEmpty {
                EmptyGoalsCard()
            } else {
                GoalsOverviewCard(goals: viewModel.activeGoals)
            }
        }
    }
}

// MARK: - Goals Overview Card

private struct GoalsOverviewCard: View {
    let goals: [CareerGoal]

    private var overallProgress: Double {
        guard !goals.isEmpty else { return 0 }
        let total = goals.reduce(0) { $0 + $1.progress }
        return Double(total) / Double(goals.count * 100)
    }

    var body: some View {
        TappableCard(action: {
            // Navigate to career goals
        }) {
            VStack(spacing: Spacing.lg) {
                // Overall progress
                HStack(spacing: Spacing.lg) {
                    ProgressRing(
                        progress: overallProgress,
                        size: 70,
                        lineWidth: 8
                    )

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("\(goals.count) Active Goals")
                            .font(Typography.headline)
                            .foregroundStyle(Colors.textPrimary)

                        Text("Overall progress")
                            .font(Typography.callout)
                            .foregroundStyle(Colors.textSecondary)
                    }

                    Spacer()
                }

                // Top 3 goals
                VStack(spacing: Spacing.sm) {
                    ForEach(goals.prefix(3)) { goal in
                        GoalProgressRow(goal: goal)
                    }
                }
            }
        }
    }
}

// MARK: - Goal Progress Row

private struct GoalProgressRow: View {
    let goal: CareerGoal

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Category icon
            Image(systemName: goal.category.icon)
                .font(.caption)
                .foregroundStyle(goal.category.color)
                .frame(width: 20)
                .accessibilityHidden(true)

            // Title
            Text(goal.title)
                .font(Typography.callout)
                .foregroundStyle(Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Progress
            HStack(spacing: Spacing.xs) {
                ProgressBar(
                    progress: goal.progressPercentage,
                    height: 6,
                    progressColor: goal.status.color
                )
                .frame(width: 60)

                Text("\(goal.progress)%")
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.title), \(goal.progress) percent complete")
    }
}

// MARK: - Empty Goals Card

private struct EmptyGoalsCard: View {
    var body: some View {
        Card {
            VStack(spacing: Spacing.md) {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Colors.textTertiary)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xs) {
                    Text("Set Your First Goal")
                        .font(Typography.headline)
                        .foregroundStyle(Colors.textPrimary)

                    Text("Track your career growth by setting goals and recording achievements")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                NavigationLink(destination: AddGoalView(onAdd: { _ in })) {
                    Text("Add Goal")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Achievements Highlight

struct RecentAchievementsCard: View {
    let achievements: [Achievement]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)

                    Text("Recent Achievements")
                        .font(Typography.subheadline)
                        .foregroundStyle(Colors.textSecondary)
                }

                ForEach(achievements.prefix(2)) { achievement in
                    HStack {
                        Text(achievement.title)
                            .font(Typography.body)
                            .lineLimit(1)

                        Spacer()

                        Text(achievement.formattedDate)
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Career Progress Card") {
    let previewGoals = [
        CareerGoal(
            title: "Become Senior Engineer",
            category: .technical,
            status: .inProgress,
            priority: .primary,
            progress: 45
        ),
        CareerGoal(
            title: "Improve Public Speaking",
            category: .communication,
            status: .inProgress,
            priority: .secondary,
            progress: 30
        )
    ]

    let previewAchievements = [
        Achievement(
            title: "Led API Migration Project",
            dateAchieved: Date().addingTimeInterval(-86400 * 30),
            tags: ["Technical Leadership"]
        ),
        Achievement(
            title: "Mentored Junior Developer",
            dateAchieved: Date().addingTimeInterval(-86400 * 14),
            tags: ["Mentoring"]
        )
    ]

    return ScrollView {
        VStack(spacing: Spacing.lg) {
            CareerProgressCard(viewModel: {
                let vm = HomeViewModel()
                return vm
            }())

            Divider()

            // With goals
            GoalsOverviewCard(goals: previewGoals)

            Divider()

            // Empty state
            EmptyGoalsCard()

            Divider()

            // Achievements
            RecentAchievementsCard(achievements: previewAchievements)
        }
        .padding()
    }
}
