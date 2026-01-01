import SwiftUI

/// View for sharing/exporting the meeting agenda
struct ShareAgendaView: View {
    @ObservedObject var viewModel: AgendaBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .slack
    @State private var showingCopiedConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Format picker
                Picker("Format", selection: $selectedFormat) {
                    ForEach([ExportFormat.slack, .teams, .markdown, .plainText], id: \.self) { format in
                        Label(format.displayName, systemImage: format.icon)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Preview
                ScrollView {
                    Text(viewModel.exportAgenda(format: selectedFormat))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(Colors.backgroundSecondary)

                Divider()

                // Actions
                VStack(spacing: Spacing.md) {
                    Button(action: copyToClipboard) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: shareViaSheet) {
                        Label("Share...", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Share Agenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showingCopiedConfirmation {
                    CopiedConfirmationView()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func copyToClipboard() {
        let text = viewModel.exportAgenda(format: selectedFormat)
        UIPasteboard.general.string = text
        Theme.successHaptic()

        withAnimation {
            showingCopiedConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingCopiedConfirmation = false
            }
        }
    }

    private func shareViaSheet() {
        let text = viewModel.exportAgenda(format: selectedFormat)
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Copied Confirmation

private struct CopiedConfirmationView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Colors.success)

            Text("Copied!")
                .font(Typography.headline)
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
    }
}

// MARK: - Preview

#Preview("Share Agenda") {
    ShareAgendaView(viewModel: AgendaBuilderViewModel(meeting: Meeting.sample))
}
