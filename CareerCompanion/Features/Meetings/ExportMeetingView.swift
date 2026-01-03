import SwiftUI

/// Full-screen view for exporting meeting content with live preview
struct ExportMeetingView: View {
    @Environment(\.dismiss) private var dismiss

    let meeting: Meeting
    let managerName: String
    var agendaItems: [AgendaItem] = []
    var actionItems: [ActionItem] = []
    var previousMeeting: Meeting? = nil

    @State private var selectedTemplate: ExportTemplate = .summary
    @State private var showCopiedOverlay = false

    private var exportText: String {
        MeetingExportService.shared.generateExport(
            meeting: meeting,
            template: selectedTemplate,
            managerName: managerName,
            agendaItems: agendaItems,
            actionItems: actionItems,
            previousMeeting: previousMeeting
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Template picker
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(ExportTemplate.allCases) { template in
                        Text(template.displayName).tag(template)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Preview area
                ScrollView {
                    Text(exportText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .background(Color(uiColor: .secondarySystemBackground))

                Divider()

                // Action buttons
                HStack(spacing: Spacing.md) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    ShareLink(item: exportText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Export Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExportStyleSettingsView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .overlay {
                if showCopiedOverlay {
                    CopiedOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func copyToClipboard() {
        MeetingExportService.shared.copyToClipboard(exportText)
        Theme.successHaptic()

        withAnimation(.spring(response: 0.3)) {
            showCopiedOverlay = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopiedOverlay = false
            }
        }
    }
}

// MARK: - Copied Overlay

private struct CopiedOverlay: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Copied!")
                .font(Typography.headline)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
}

// MARK: - Export Style Settings

struct ExportStyleSettingsView: View {
    @State private var selectedStyle = AppSettings.shared.exportStyle

    var body: some View {
        Form {
            Section {
                ForEach(ExportStyle.allCases) { style in
                    Button {
                        selectedStyle = style
                        AppSettings.shared.exportStyle = style
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.displayName)
                                    .foregroundStyle(Colors.textPrimary)
                                Text(style.description)
                                    .font(Typography.caption1)
                                    .foregroundStyle(Colors.textSecondary)
                            }

                            Spacer()

                            if selectedStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Style")
            } footer: {
                Text("Choose how your exported text will be formatted.")
            }

            Section {
                NavigationLink("Customize Sections") {
                    ExportSectionsCustomizerView()
                }
            } header: {
                Text("Sections")
            }
        }
        .navigationTitle("Export Style")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sections Customizer

struct ExportSectionsCustomizerView: View {
    @State private var includedSections = AppSettings.shared.exportIncludedSections

    var body: some View {
        Form {
            Section {
                ForEach(ExportSection.allCases.filter { $0 != .header }) { section in
                    Toggle(isOn: binding(for: section)) {
                        HStack {
                            Text(section.casualEmoji)
                            Text(section.displayName)
                        }
                    }
                }
            } header: {
                Text("Include in Export")
            } footer: {
                Text("Toggle which sections appear in your exported meeting notes. Header is always included.")
            }
        }
        .navigationTitle("Sections")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for section: ExportSection) -> Binding<Bool> {
        Binding(
            get: { includedSections.contains(section.rawValue) },
            set: { newValue in
                if newValue {
                    includedSections.insert(section.rawValue)
                } else {
                    includedSections.remove(section.rawValue)
                }
                AppSettings.shared.exportIncludedSections = includedSections
            }
        )
    }
}

// MARK: - Preview

#Preview("Export View") {
    let meeting = Meeting(
        managerID: UUID(),
        date: Date(),
        status: .completed,
        notes: "Great discussion about Q4 goals.",
        wentWell: ["Completed API migration", "Got positive feedback"],
        didntGoWell: ["Missed documentation deadline"],
        blockers: ["Waiting for design assets"],
        nextWeekGoals: ["Ship feature to production", "Start user testing"]
    )

    return ExportMeetingView(
        meeting: meeting,
        managerName: "Sarah Johnson",
        agendaItems: [
            AgendaItem(meetingID: meeting.id, title: "Review Q4 objectives", order: 0),
            AgendaItem(meetingID: meeting.id, title: "Discuss career growth", order: 1)
        ],
        actionItems: [
            ActionItem(title: "Complete API docs", dueDate: Date().addingTimeInterval(86400 * 7)),
            ActionItem(title: "Review budget", priority: .high, owner: .manager)
        ]
    )
}

#Preview("Style Settings") {
    NavigationStack {
        ExportStyleSettingsView()
    }
}
