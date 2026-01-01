import SwiftUI

/// View for adding a new career goal
struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: GoalCategory = .technical
    @State private var hasTargetDate = true
    @State private var targetDate = Date().addingTimeInterval(86400 * 90) // 3 months
    @State private var priority: GoalPriority = .primary
    @State private var successMetrics = ""
    @State private var trackingMethod = ""

    let onAdd: (CareerGoal) -> Void

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Title", text: $title)
                        .accessibilityLabel("Goal title")

                    TextField("Why is this goal important?", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Goal description")
                } header: {
                    Text("Goal")
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(GoalPriority.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }

                Section {
                    Toggle("Set Target Date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }

                Section {
                    TextField("How will you measure success?", text: $successMetrics, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("How will you track progress?", text: $trackingMethod)
                } header: {
                    Text("Success Metrics")
                } footer: {
                    Text("Be specific about how you'll know when you've achieved this goal.")
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addGoal()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func addGoal() {
        let goal = CareerGoal(
            title: title.trimmingCharacters(in: .whitespaces),
            goalDescription: description.trimmingCharacters(in: .whitespaces),
            category: category,
            targetDate: hasTargetDate ? targetDate : nil,
            status: .notStarted,
            priority: priority,
            successMetrics: successMetrics.trimmingCharacters(in: .whitespaces),
            trackingMethod: trackingMethod.trimmingCharacters(in: .whitespaces)
        )
        onAdd(goal)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add Goal") {
    AddGoalView { goal in
        print("Added: \(goal.title)")
    }
}
