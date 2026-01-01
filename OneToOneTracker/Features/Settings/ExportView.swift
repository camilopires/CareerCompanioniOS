import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @StateObject private var exportService = ExportImportService.shared
    @State private var selectedFormat: DataExportFormat = .json
    @State private var exportedData: Data?
    @State private var exportedFilename = ""
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            // Format selection section
            Section {
                ForEach(DataExportFormat.allCases) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        HStack {
                            Image(systemName: format.icon)
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(format.displayName)
                                    .font(Typography.body)
                                    .foregroundStyle(Colors.textPrimary)

                                Text(format.description)
                                    .font(Typography.caption1)
                                    .foregroundStyle(Colors.textSecondary)
                            }

                            Spacer()

                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Export Format")
            }

            // Export button section
            Section {
                Button {
                    Task {
                        await performExport()
                    }
                } label: {
                    HStack {
                        Spacer()

                        if exportService.isExporting {
                            ProgressView()
                                .padding(.trailing, Spacing.sm)
                            Text("Exporting...")
                        } else {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }

                        Spacer()
                    }
                    .font(Typography.headline)
                }
                .disabled(exportService.isExporting)

                if exportService.isExporting {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ProgressView(value: exportService.progress)
                            .tint(Color.accentColor)

                        Text(exportService.statusMessage)
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
            } footer: {
                Text("Your data will be exported from iCloud. This may take a moment depending on your data size.")
            }

            // Information section
            Section {
                InfoRow(icon: "lock.shield", title: "Private & Secure",
                        description: "Exported files contain your personal data. Keep them secure.")

                InfoRow(icon: "arrow.triangle.2.circlepath", title: "Full Sync",
                        description: "Export includes all synced data from your iCloud account.")

                InfoRow(icon: "doc.badge.plus", title: "Import Later",
                        description: "JSON exports can be imported back into Career Companion.")
            } header: {
                Text("About Export")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportedData {
                ShareSheet(items: [ExportDocument(data: data, filename: exportedFilename)])
            }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func performExport() async {
        do {
            let data: Data
            switch selectedFormat {
            case .json:
                data = try await exportService.exportToJSON()
            case .csv:
                data = try await exportService.exportToCSV()
            }

            exportedData = data
            exportedFilename = exportService.generateFilename(format: selectedFormat)
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.headline)

                Text(description)
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)
            }
        }
    }
}

// MARK: - Export Document

struct ExportDocument: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { document in
            document.data
        }
    }
}

// MARK: - Temporary File for Sharing

extension ExportDocument {
    func temporaryURL() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExportView()
    }
}
