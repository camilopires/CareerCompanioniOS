import SwiftUI

/// View for adding a new achievement
struct AddAchievementView: View {
    @Environment(\.dismiss) private var dismiss

    let goals: [CareerGoal]

    @State private var title = ""
    @State private var description = ""
    @State private var dateAchieved = Date()
    @State private var impactStatement = ""
    @State private var selectedGoalIDs: Set<UUID> = []
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var visibility: Visibility = .privateOnly

    let onAdd: (Achievement) -> Void

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What did you achieve?", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    DatePicker("Date", selection: $dateAchieved, displayedComponents: .date)
                } header: {
                    Text("Achievement")
                }

                Section {
                    TextField("Quantify the impact (e.g., 'Reduced load time by 40%')", text: $impactStatement, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Impact")
                } footer: {
                    Text("Specific, measurable impacts are great for performance reviews.")
                }

                if !goals.isEmpty {
                    Section {
                        ForEach(goals.filter { $0.isActive }) { goal in
                            Toggle(isOn: Binding(
                                get: { selectedGoalIDs.contains(goal.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedGoalIDs.insert(goal.id)
                                    } else {
                                        selectedGoalIDs.remove(goal.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: goal.category.icon)
                                        .foregroundStyle(goal.category.color)
                                    Text(goal.title)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } header: {
                        Text("Link to Goals")
                    } footer: {
                        Text("Connect this achievement to your career goals.")
                    }
                }

                Section {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { tags.removeAll { $0 == tag } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Colors.textTertiary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add tag...", text: $newTag)
                            .submitLabel(.done)
                            .onSubmit(addTag)

                        if !newTag.isEmpty {
                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                }

                Section {
                    Picker("Visibility", selection: $visibility) {
                        ForEach(Visibility.allCases) { v in
                            Label(v.displayName, systemImage: v.icon)
                                .tag(v)
                        }
                    }
                } footer: {
                    Text("Control who can see this achievement in reports.")
                }
            }
            .navigationTitle("New Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAchievement()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }

    private func addAchievement() {
        let achievement = Achievement(
            title: title.trimmingCharacters(in: .whitespaces),
            achievementDescription: description.trimmingCharacters(in: .whitespaces),
            dateAchieved: dateAchieved,
            impactStatement: impactStatement.trimmingCharacters(in: .whitespaces),
            goalIDs: Array(selectedGoalIDs),
            tags: tags,
            visibility: visibility
        )
        onAdd(achievement)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add Achievement") {
    AddAchievementView(goals: CareerGoal.samples) { achievement in
        print("Added: \(achievement.title)")
    }
}
