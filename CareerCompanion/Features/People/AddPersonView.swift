import SwiftUI

/// View for adding a new person (manager, report, mentor, etc.)
struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var selectedRelationshipType = "My Manager"
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingAddCustomType = false
    @State private var customTypeName = ""
    @State private var showDemoExitPrompt = false

    /// Optional callback when a person is successfully added
    var onPersonAdded: ((Manager) -> Void)?

    private var userRole: UserRole { AppSettings.shared.userRole }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                // Relationship Type Section
                Section {
                    Picker("Relationship", selection: $selectedRelationshipType) {
                        // Special types first (drive app mode)
                        Section {
                            Text("My Manager").tag("My Manager")
                            Text("Direct Report").tag("Direct Report")
                        }

                        // Other default types
                        Section {
                            ForEach(AppSettings.shared.allRelationshipTypes.filter {
                                $0 != "My Manager" && $0 != "Direct Report"
                            }, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        customTypeName = ""
                        showingAddCustomType = true
                    } label: {
                        Label("Add Custom Type", systemImage: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    Text("Relationship")
                } footer: {
                    if selectedRelationshipType == "My Manager" || selectedRelationshipType == "Direct Report" {
                        Text("This person will appear in your main dashboard section.")
                    } else {
                        Text("This person will appear in the \"Other 1:1s\" section.")
                    }
                }

                // Tags Section (optional)
                Section {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textInputAutocapitalization(.never)
                        Button {
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                tags.append(newTag)
                                newTag = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.isEmpty)
                    }
                } header: {
                    Text("Tags (optional)")
                } footer: {
                    Text("Tags help you filter and organize your 1:1s.")
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if AppSettings.shared.isDemoMode {
                            showDemoExitPrompt = true
                        } else {
                            savePerson()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Add Custom Type", isPresented: $showingAddCustomType) {
                TextField("Type name", text: $customTypeName)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    if !customTypeName.isEmpty {
                        AppSettings.shared.addCustomRelationshipType(customTypeName)
                        selectedRelationshipType = customTypeName
                    }
                }
            } message: {
                Text("Enter a name for the new relationship type.")
            }
            .alert("Exit Demo Mode?", isPresented: $showDemoExitPrompt) {
                Button("Stay in Demo", role: .cancel) {
                    savePerson()
                }
                Button("Exit Demo Mode") {
                    AppSettings.shared.isDemoMode = false
                    savePerson()
                }
            } message: {
                Text("You're creating real data. You can turn demo mode back on in Settings.")
            }
            .onAppear {
                // Pre-select based on current user role
                if userRole == .manager {
                    selectedRelationshipType = "Direct Report"
                }
            }
        }
    }

    private func savePerson() {
        let person = Manager(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            relationshipType: selectedRelationshipType,
            tags: tags
        )

        Task {
            let savedPerson = try? await CloudKitManager.shared.save(person)
            await MainActor.run {
                onPersonAdded?(savedPerson ?? person)
                dismiss()
            }
        }
    }
}

#Preview {
    AddPersonView()
}

#Preview("With Callback") {
    AddPersonView { person in
        print("Added: \(person.name)")
    }
}
