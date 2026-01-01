import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @StateObject private var importService = ExportImportService.shared
    @State private var showingFilePicker = false
    @State private var selectedFileData: Data?
    @State private var previewData: ExportData?
    @State private var conflictResolution: ImportConflictResolution = .skip
    @State private var importResult: ImportResult?
    @State private var showingResult = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            // File selection section
            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Select File")
                                .font(Typography.body)
                                .foregroundStyle(Colors.textPrimary)

                            Text(selectedFileData != nil ? "File selected" : "Choose a JSON backup file")
                                .font(Typography.caption1)
                                .foregroundStyle(selectedFileData != nil ? Colors.success : Colors.textSecondary)
                        }

                        Spacer()

                        if selectedFileData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Colors.success)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Colors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Import File")
            } footer: {
                Text("Select a JSON file previously exported from OneToOne Tracker.")
            }

            // Preview section
            if let preview = previewData {
                Section {
                    PreviewRow(icon: "calendar", label: "Export Date", value: preview.formattedExportDate)
                    PreviewRow(icon: "app.badge", label: "App Version", value: preview.appVersion)
                    PreviewRow(icon: "person.2", label: "Managers", value: "\(preview.managers.count)")
                    PreviewRow(icon: "calendar.badge.clock", label: "Meetings", value: "\(preview.meetings.count)")
                    PreviewRow(icon: "checklist", label: "Action Items", value: "\(preview.actionItems.count)")
                    PreviewRow(icon: "star", label: "Career Goals", value: "\(preview.careerGoals.count)")
                    PreviewRow(icon: "trophy", label: "Achievements", value: "\(preview.achievements.count)")
                    PreviewRow(icon: "list.bullet", label: "Agenda Items", value: "\(preview.agendaItems.count)")
                } header: {
                    Text("File Contents")
                }
            }

            // Conflict resolution section
            if previewData != nil {
                Section {
                    ForEach(ImportConflictResolution.allCases) { resolution in
                        Button {
                            conflictResolution = resolution
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text(resolution.displayName)
                                        .font(Typography.body)
                                        .foregroundStyle(Colors.textPrimary)

                                    Text(resolution.description)
                                        .font(Typography.caption1)
                                        .foregroundStyle(Colors.textSecondary)
                                }

                                Spacer()

                                if conflictResolution == resolution {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Duplicate Handling")
                } footer: {
                    Text("Choose how to handle items that already exist in your data.")
                }
            }

            // Import button section
            if previewData != nil {
                Section {
                    Button {
                        Task {
                            await performImport()
                        }
                    } label: {
                        HStack {
                            Spacer()

                            if importService.isImporting {
                                ProgressView()
                                    .padding(.trailing, Spacing.sm)
                                Text("Importing...")
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Data")
                            }

                            Spacer()
                        }
                        .font(Typography.headline)
                    }
                    .disabled(importService.isImporting)

                    if importService.isImporting {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ProgressView(value: importService.progress)
                                .tint(Color.accentColor)

                            Text(importService.statusMessage)
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                } footer: {
                    Text("Imported data will be saved to your iCloud account and synced across devices.")
                }
            }

            // Warning section
            Section {
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Colors.warning)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Important")
                            .font(Typography.headline)

                        Text("Importing data will add items to your existing data. This action cannot be undone. Consider exporting your current data first as a backup.")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
            }
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Complete", isPresented: $showingResult) {
            Button("OK", role: .cancel) {}
        } message: {
            if let result = importResult {
                Text(result.summary + (result.hasErrors ? "\n\nSome items failed to import." : ""))
            }
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file."
                showingError = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                selectedFileData = data
                previewData = try importService.previewImport(data: data)
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
                showingError = true
                selectedFileData = nil
                previewData = nil
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func performImport() async {
        guard let data = selectedFileData else { return }

        do {
            let result = try await importService.importFromJSON(
                data: data,
                conflictResolution: conflictResolution
            )
            importResult = result
            showingResult = true

            // Reset state after successful import
            if !result.hasErrors {
                selectedFileData = nil
                previewData = nil
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview Row

private struct PreviewRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(Typography.body)

            Spacer()

            Text(value)
                .font(Typography.body)
                .foregroundStyle(Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ImportView()
    }
}
