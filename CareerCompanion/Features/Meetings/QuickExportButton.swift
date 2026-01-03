import SwiftUI

/// Compact export button with menu for quick copy or full preview
struct QuickExportButton: View {
    let meeting: Meeting
    let managerName: String
    var agendaItems: [AgendaItem] = []
    var actionItems: [ActionItem] = []
    var previousMeeting: Meeting? = nil

    @State private var showExportSheet = false
    @State private var showCopiedToast = false

    var body: some View {
        Menu {
            Button {
                quickCopy(.summary)
            } label: {
                Label("Copy Summary", systemImage: "doc.text")
            }

            Button {
                quickCopy(.prep)
            } label: {
                Label("Copy Prep", systemImage: "list.clipboard")
            }

            Divider()

            Button {
                showExportSheet = true
            } label: {
                Label("Export with Preview...", systemImage: "eye")
            }
        } label: {
            Image(systemName: "doc.on.doc")
                .accessibilityLabel("Export meeting")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportMeetingView(
                meeting: meeting,
                managerName: managerName,
                agendaItems: agendaItems,
                actionItems: actionItems,
                previousMeeting: previousMeeting
            )
        }
        .overlay {
            if showCopiedToast {
                QuickCopiedToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func quickCopy(_ template: ExportTemplate) {
        let text = MeetingExportService.shared.generateExport(
            meeting: meeting,
            template: template,
            managerName: managerName,
            agendaItems: agendaItems,
            actionItems: actionItems,
            previousMeeting: previousMeeting
        )

        MeetingExportService.shared.copyToClipboard(text)
        Theme.successHaptic()

        withAnimation(.spring(response: 0.3)) {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }
}

// MARK: - Quick Copied Toast

private struct QuickCopiedToast: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Copied!")
                .font(Typography.caption1)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .offset(y: -60)
    }
}

// MARK: - Toolbar Button Style

/// A simpler version for toolbar use
struct ExportToolbarButton: View {
    let meeting: Meeting
    let managerName: String
    var agendaItems: [AgendaItem] = []
    var actionItems: [ActionItem] = []

    @State private var showExportSheet = false

    var body: some View {
        Button {
            showExportSheet = true
        } label: {
            Image(systemName: "doc.on.doc")
                .accessibilityLabel("Export meeting")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportMeetingView(
                meeting: meeting,
                managerName: managerName,
                agendaItems: agendaItems,
                actionItems: actionItems
            )
        }
    }
}

// MARK: - Preview

#Preview("Quick Export Button") {
    let meeting = Meeting(
        managerID: UUID(),
        date: Date(),
        status: .completed,
        wentWell: ["Great progress on API"],
        blockers: ["Waiting for review"]
    )

    return VStack {
        QuickExportButton(
            meeting: meeting,
            managerName: "Sarah Johnson"
        )
    }
    .padding()
}
