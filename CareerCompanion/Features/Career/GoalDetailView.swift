import SwiftUI

/// Detailed view of a career goal
struct GoalDetailView: View {
    @State private var goal: CareerGoal
    @State private var isEditing = false
    @State private var linkedAchievements: [Achievement] = []

    init(goal: CareerGoal) {
        self._goal = State(initialValue: goal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Progress card
                ProgressCard(goal: goal, onUpdateProgress: updateProgress)

                // Details
                DetailsCard(goal: $goal, isEditing: isEditing)

                // Metrics
                if !goal.successMetrics.isEmpty || isEditing {
                    MetricsCard(goal: $goal, isEditing: isEditing)
                }

                // Linked achievements
                LinkedAchievementsSection(achievements: linkedAchievements, goalID: goal.id)

                // Mark achieved button
                if goal.status != .achieved {
                    Button(action: markAchieved) {
                        Label("Mark as Achieved", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveChanges() }
                    isEditing.toggle()
                }
            }
        }
        .task {
            await loadAchievements()
        }
    }

    private func updateProgress(_ newProgress: Int) {
        goal.updateProgress(newProgress)
        saveChanges()
    }

    private func markAchieved() {
        goal.markAchieved()
        saveChanges()
        Theme.successHaptic()
    }

    private func saveChanges() {
        Task {
            _ = try? await CloudKitManager.shared.save(goal)
        }
    }

    private func loadAchievements() async {
        do {
            let all: [Achievement] = try await CloudKitManager.shared.fetch()
            linkedAchievements = all.filter { $0.goalIDs.contains(goal.id) }
        } catch {}
    }
}

// MARK: - Progress Card

private struct ProgressCard: View {
    let goal: CareerGoal
    let onUpdateProgress: (Int) -> Void

    @State private var sliderProgress: Double

    init(goal: CareerGoal, onUpdateProgress: @escaping (Int) -> Void) {
        self.goal = goal
        self.onUpdateProgress = onUpdateProgress
        self._sliderProgress = State(initialValue: Double(goal.progress))
    }

    var body: some View {
        Card(style: .elevated) {
            VStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xl) {
                    ProgressRing(
                        progress: goal.progressPercentage,
                        size: 100,
                        lineWidth: 12,
                        progressColor: goal.status.color
                    )

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(goal.title)
                            .font(Typography.headline)

                        Label(goal.status.displayName, systemImage: goal.status.icon)
                            .font(Typography.callout)
                            .foregroundStyle(goal.status.color)

                        if let days = goal.daysUntilTarget {
                            Text(days > 0 ? "\(days) days remaining" : "Target date passed")
                                .font(Typography.caption1)
                                .foregroundStyle(days > 0 ? Colors.textSecondary : Colors.error)
                        }
                    }

                    Spacer()
                }

                // Progress slider
                VStack(spacing: Spacing.xs) {
                    Slider(value: $sliderProgress, in: 0...100, step: 5)
                        .onChange(of: sliderProgress) { _, newValue in
                            onUpdateProgress(Int(newValue))
                        }

                    Text("Drag to update progress")
                        .font(Typography.caption2)
                        .foregroundStyle(Colors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Details Card

private struct DetailsCard: View {
    @Binding var goal: CareerGoal
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .font(Typography.headline)

            Card {
                VStack(spacing: Spacing.md) {
                    // Description
                    if isEditing || !goal.goalDescription.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)

                            if isEditing {
                                TextField("Why is this goal important?", text: $goal.goalDescription, axis: .vertical)
                                    .lineLimit(3...6)
                            } else {
                                Text(goal.goalDescription)
                                    .font(Typography.body)
                            }
                        }

                        Divider()
                    }

                    // Category
                    HStack {
                        Text("Category")
                        Spacer()
                        if isEditing {
                            Picker("", selection: $goal.category) {
                                ForEach(GoalCategory.allCases) { cat in
                                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                                }
                            }
                        } else {
                            Label(goal.category.displayName, systemImage: goal.category.icon)
                                .foregroundStyle(goal.category.color)
                        }
                    }

                    Divider()

                    // Target date
                    HStack {
                        Text("Target Date")
                        Spacer()
                        if isEditing {
                            DatePicker("", selection: Binding(
                                get: { goal.targetDate ?? Date() },
                                set: { goal.targetDate = $0 }
                            ), displayedComponents: .date)
                        } else {
                            Text(goal.formattedTargetDate ?? "Not set")
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }

                    Divider()

                    // Priority
                    HStack {
                        Text("Priority")
                        Spacer()
                        if isEditing {
                            Picker("", selection: $goal.priority) {
                                ForEach(GoalPriority.allCases) { p in
                                    Text(p.displayName).tag(p)
                                }
                            }
                        } else {
                            Label(goal.priority.displayName, systemImage: goal.priority.icon)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Metrics Card

private struct MetricsCard: View {
    @Binding var goal: CareerGoal
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Success Metrics")
                .font(Typography.headline)

            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if isEditing {
                        TextField("How will you measure success?", text: $goal.successMetrics, axis: .vertical)
                            .lineLimit(2...4)
                    } else {
                        Text(goal.successMetrics)
                            .font(Typography.body)
                    }

                    if isEditing || !goal.trackingMethod.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Tracking Method")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)

                            if isEditing {
                                TextField("How will you track progress?", text: $goal.trackingMethod)
                            } else {
                                Text(goal.trackingMethod)
                                    .font(Typography.body)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Linked Achievements

private struct LinkedAchievementsSection: View {
    let achievements: [Achievement]
    let goalID: UUID

    var body: some View {
        if !achievements.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Linked Achievements")
                    .font(Typography.headline)

                VStack(spacing: Spacing.sm) {
                    ForEach(achievements) { achievement in
                        Card {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)

                                VStack(alignment: .leading) {
                                    Text(achievement.title)
                                        .font(Typography.body)
                                    Text(achievement.formattedDate)
                                        .font(Typography.caption1)
                                        .foregroundStyle(Colors.textSecondary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Goal Detail") {
    let previewGoal = CareerGoal(
        title: "Become Senior Engineer",
        goalDescription: "Develop skills for promotion",
        category: .technical,
        targetDate: Date().addingTimeInterval(86400 * 180),
        status: .inProgress,
        priority: .primary,
        successMetrics: "Lead 2 major projects, mentor junior developers",
        progress: 45,
        skills: ["System Design", "Mentoring", "Leadership"]
    )
    return NavigationStack {
        GoalDetailView(goal: previewGoal)
    }
}
