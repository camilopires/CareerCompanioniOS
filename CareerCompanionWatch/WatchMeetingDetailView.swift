import SwiftUI

struct WatchMeetingDetailView: View {
    let meeting: Meeting
    let managerName: String

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(managerName)
                        .font(.headline)

                    Text(meeting.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    StatusBadge(status: meeting.status)
                }
            }

            if !meeting.notes.isEmpty {
                Section("Notes") {
                    Text(meeting.notes)
                        .font(.caption)
                }
            }

            if !meeting.wentWell.isEmpty {
                Section("Went Well") {
                    ForEach(meeting.wentWell, id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption)
                    }
                }
            }

            if !meeting.blockers.isEmpty {
                Section("Blockers") {
                    ForEach(meeting.blockers, id: \.self) { blocker in
                        Text("• \(blocker)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Meeting")
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: MeetingStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .scheduled: return .blue.opacity(0.2)
        case .inProgress: return .green.opacity(0.2)
        case .completed: return .gray.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        case .skipped: return .orange.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .cancelled: return .red
        case .skipped: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    let meeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400)
    )
    return NavigationStack {
        WatchMeetingDetailView(meeting: meeting, managerName: "Sarah Johnson")
    }
}
