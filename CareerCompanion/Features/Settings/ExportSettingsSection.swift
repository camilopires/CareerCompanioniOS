import SwiftUI

/// Settings section for configuring meeting export preferences
struct ExportSettingsSection: View {
    @State private var selectedStyle = AppSettings.shared.exportStyle

    var body: some View {
        Section {
            // Style picker
            Picker("Style", selection: $selectedStyle) {
                ForEach(ExportStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .onChange(of: selectedStyle) { _, newValue in
                AppSettings.shared.exportStyle = newValue
            }

            // Customize sections
            NavigationLink {
                ExportSectionsSettingsView()
            } label: {
                HStack {
                    Text("Customize Sections")
                    Spacer()
                    Text("\(AppSettings.shared.exportIncludedSections.count) enabled")
                        .foregroundStyle(Colors.textTertiary)
                }
            }
        } header: {
            Text("Meeting Export")
        } footer: {
            Text("Customize how meetings are formatted when exporting to Google Docs, Word, or other apps.")
        }
    }
}

// MARK: - Sections Settings

struct ExportSectionsSettingsView: View {
    @State private var includedSections = AppSettings.shared.exportIncludedSections

    var body: some View {
        Form {
            Section {
                ForEach(ExportSection.allCases.filter { $0 != .header }) { section in
                    Toggle(isOn: binding(for: section)) {
                        HStack(spacing: Spacing.sm) {
                            Text(section.casualEmoji)
                                .frame(width: 24)
                            Text(section.displayName)
                        }
                    }
                }
            } header: {
                Text("Include in Export")
            } footer: {
                Text("Toggle which sections appear in your exported meeting notes. The header (date, person, meeting type) is always included.")
            }

            Section {
                Button("Reset to Defaults") {
                    includedSections = Set(ExportSection.allCases.map { $0.rawValue })
                    AppSettings.shared.exportIncludedSections = includedSections
                }
            }
        }
        .navigationTitle("Export Sections")
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

#Preview("Export Settings Section") {
    NavigationStack {
        Form {
            ExportSettingsSection()
        }
    }
}

#Preview("Sections Settings") {
    NavigationStack {
        ExportSectionsSettingsView()
    }
}
