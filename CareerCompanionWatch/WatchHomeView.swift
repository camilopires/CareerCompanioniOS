import SwiftUI

struct WatchHomeView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.hasActiveMeeting, let meeting = sessionManager.activeMeeting {
                    ActiveMeetingWatchView(meeting: meeting)
                } else {
                    NoMeetingView()
                }
            }
            .navigationTitle("1:1 Tracker")
        }
        .onAppear {
            sessionManager.startSession()
            // Poll immediately on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sessionManager.requestMeetingStatus()
            }
        }
    }
}

// MARK: - No Meeting View

private struct NoMeetingView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Start a meeting on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Your active meeting will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

        }
        .padding()
    }
}

// MARK: - Active Meeting View

private struct ActiveMeetingWatchView: View {
    let meeting: WatchMeetingData
    @ObservedObject var sessionManager = WatchSessionManager.shared

    var body: some View {
        List {
            // Meeting Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(meeting.managerName)
                        .font(.headline)

                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("In Progress")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Agenda Section
            if !meeting.agenda.isEmpty {
                Section("Agenda") {
                    ForEach(meeting.agenda, id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption)
                    }
                }
            }

            // Blockers Section
            if !meeting.blockers.isEmpty {
                Section("Blockers") {
                    ForEach(meeting.blockers, id: \.self) { blocker in
                        Text("• \(blocker)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Action Items Section
            if !meeting.actionItems.isEmpty {
                Section("Action Items") {
                    ForEach(meeting.actionItems) { item in
                        HStack {
                            Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.completed ? .green : .secondary)
                            Text(item.title)
                                .font(.caption)
                                .strikethrough(item.completed)
                                .foregroundStyle(item.completed ? .secondary : .primary)
                        }
                    }
                }
            }

            // Complete Meeting Button
            Section {
                Button(action: {
                    sessionManager.completeMeeting(meeting.id)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Meeting")
                    }
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("No Meeting") {
    WatchHomeView()
}
