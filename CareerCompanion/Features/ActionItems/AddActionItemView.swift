import SwiftUI

/// View for adding a new action item
struct AddActionItemView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var priority: Priority = .medium
    @State private var owner: Owner = .me
    @State private var showDemoExitPrompt = false

    let onAdd: (ActionItem) -> Void

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs to be done?", text: $title)
                        .accessibilityLabel("Title")

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Description")
                }

                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }

                    Picker("Owner", selection: $owner) {
                        ForEach(Owner.allCases) { owner in
                            Label(owner.displayName, systemImage: owner.icon)
                                .tag(owner)
                        }
                    }
                }
            }
            .navigationTitle("New Action Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if AppSettings.shared.isDemoMode {
                            showDemoExitPrompt = true
                        } else {
                            addItem()
                        }
                    }
                    .disabled(!isValid)
                    .accessibilityHint(isValid ? "Creates new action item" : "Enter a title to enable this button")
                }
            }
            .alert("Exit Demo Mode?", isPresented: $showDemoExitPrompt) {
                Button("Stay in Demo", role: .cancel) {
                    addItem()
                }
                Button("Exit Demo Mode") {
                    AppSettings.shared.isDemoMode = false
                    addItem()
                }
            } message: {
                Text("You're creating real data. You can turn demo mode back on in Settings.")
            }
        }
    }

    private func addItem() {
        let item = ActionItem(
            title: title.trimmingCharacters(in: .whitespaces),
            itemDescription: description.trimmingCharacters(in: .whitespaces),
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            owner: owner
        )
        onAdd(item)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add Action Item") {
    AddActionItemView { item in
        print("Added: \(item.title)")
    }
}
