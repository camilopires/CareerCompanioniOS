import SwiftUI

/// Modal for inputting rough notes and having AI categorize them
struct SmartNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiManager = AIManager.shared

    @State private var rawNotes = ""
    @State private var selectedSections: Set<MeetingSectionType> = [.wentWell, .didntGoWell, .blockers, .escalations]
    @State private var result: SmartNotesResult?
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var manualAssignments: [String: MeetingSectionType] = [:]

    let onApply: (SmartNotesResult, [String: MeetingSectionType]) -> Void

    var body: some View {
        NavigationStack {
            Form {
                if !showingResult {
                    inputSection
                } else {
                    resultSection
                }
            }
            .navigationTitle("Smart Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if showingResult {
                        Button("Apply") {
                            if let result = result {
                                onApply(result, manualAssignments)
                            }
                            dismiss()
                        }
                        .disabled(result == nil || (result?.totalCategorized == 0 && manualAssignments.isEmpty))
                    } else {
                        Button("Categorize") {
                            Task { await categorize() }
                        }
                        .disabled(rawNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isProcessing)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        Group {
            Section {
                TextEditor(text: $rawNotes)
                    .frame(minHeight: 150)
                    .accessibilityLabel("Rough notes input")
            } header: {
                Text("Paste your rough notes")
            } footer: {
                Text("Enter bullet points, sentences, or paragraphs. AI will categorize them into the selected sections below.")
            }

            Section {
                ForEach(MeetingSectionType.allCases.filter { $0 != .notes }) { section in
                    Toggle(isOn: Binding(
                        get: { selectedSections.contains(section) },
                        set: { isSelected in
                            if isSelected {
                                selectedSections.insert(section)
                            } else {
                                selectedSections.remove(section)
                            }
                        }
                    )) {
                        Label(section.displayName, systemImage: section.icon)
                    }
                }
            } header: {
                Text("Target Sections")
            } footer: {
                Text("Select which sections to populate. Items that don't match will be shown for manual assignment.")
            }

            if isProcessing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Analyzing notes...")
                            .font(Typography.callout)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        Group {
            if let currentResult = result {
                // Summary
                Section {
                    LabeledContent("Categorized", value: "\(currentResult.totalCategorized)")
                    LabeledContent("Needs Assignment", value: "\(currentResult.uncategorizedItems.count - manualAssignments.count)")
                } header: {
                    Text("Summary")
                }

                // Categorized items by section
                ForEach(Array(currentResult.categorizedItems.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { section in
                    if let items = currentResult.categorizedItems[section], !items.isEmpty {
                        Section {
                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top, spacing: Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Colors.success)
                                        .font(.caption)
                                    Text(item)
                                        .font(Typography.body)
                                }
                            }
                        } header: {
                            Label(section.displayName, systemImage: section.icon)
                        }
                    }
                }

                // Uncategorized items needing manual assignment
                if currentResult.hasUncategorized {
                    Section {
                        ForEach(currentResult.uncategorizedItems, id: \.self) { item in
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(item)
                                    .font(Typography.body)

                                Menu {
                                    ForEach(Array(selectedSections).sorted(by: { $0.rawValue < $1.rawValue })) { section in
                                        Button {
                                            manualAssignments[item] = section
                                        } label: {
                                            Label(section.displayName, systemImage: section.icon)
                                        }
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        manualAssignments.removeValue(forKey: item)
                                    } label: {
                                        Label("Skip this item", systemImage: "xmark")
                                    }
                                } label: {
                                    if let assigned = manualAssignments[item] {
                                        Label(assigned.displayName, systemImage: assigned.icon)
                                            .font(Typography.caption1)
                                            .foregroundStyle(Colors.success)
                                    } else {
                                        Label("Assign to section", systemImage: "arrow.right.circle")
                                            .font(Typography.caption1)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.xxs)
                        }
                    } header: {
                        Label("Needs Manual Assignment", systemImage: "questionmark.circle")
                    } footer: {
                        Text("These items couldn't be automatically categorized. Tap to assign them to a section or skip.")
                    }
                }
            }

            // Reset button (outside if let to avoid shadowing)
            if result != nil {
                Section {
                    Button("Start Over") {
                        showingResult = false
                        result = nil
                        manualAssignments = [:]
                    }
                    .foregroundStyle(Colors.error)
                }
            }
        }
    }

    // MARK: - Actions

    private func categorize() async {
        isProcessing = true

        result = await aiManager.categorizeNotes(rawNotes, selectedSections: selectedSections)

        isProcessing = false
        showingResult = true
    }
}

// MARK: - Preview

#Preview("Smart Notes - Input") {
    SmartNotesSheet { _, _ in }
}

#Preview("Smart Notes - Results") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Text("Preview")
                .sheet(isPresented: $showSheet) {
                    SmartNotesSheet { _, _ in }
                }
        }
    }
    return PreviewWrapper()
}
