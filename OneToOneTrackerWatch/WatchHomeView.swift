import SwiftUI

struct WatchHomeView: View {
    @StateObject private var viewModel = WatchHomeViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Next Meeting Section
                Section {
                    if let meeting = viewModel.nextMeeting {
                        NavigationLink(destination: WatchMeetingDetailView(meeting: meeting, managerName: viewModel.managerName(for: meeting))) {
                            NextMeetingRow(meeting: meeting, managerName: viewModel.managerName(for: meeting))
                        }
                    } else {
                        Text("No upcoming meetings")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Next 1:1", systemImage: "calendar")
                }

                // Action Items Section
                Section {
                    if viewModel.openActionItems.isEmpty {
                        Text("All caught up!")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.openActionItems.prefix(3)) { item in
                            ActionItemRow(item: item, onComplete: {
                                Task {
                                    await viewModel.completeActionItem(item)
                                }
                            })
                        }

                        if viewModel.openActionItems.count > 3 {
                            NavigationLink(destination: WatchActionItemsView(viewModel: viewModel)) {
                                Text("See all (\(viewModel.openActionItems.count))")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } header: {
                    Label("Action Items", systemImage: "checklist")
                }

                // Quick Log Section
                Section {
                    NavigationLink(destination: WatchQuickLogView(viewModel: viewModel)) {
                        Label("Log Sentiment", systemImage: "face.smiling")
                    }
                } header: {
                    Label("Quick Actions", systemImage: "bolt.fill")
                }
            }
            .navigationTitle("1:1 Tracker")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Next Meeting Row

private struct NextMeetingRow: View {
    let meeting: Meeting
    let managerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(managerName)
                .font(.headline)

            Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let countdown = countdownText {
                Text(countdown)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var countdownText: String? {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: meeting.date)

        if let days = components.day, days > 0 {
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "in \(minutes) min"
        }
        return nil
    }
}

// MARK: - Action Item Row

private struct ActionItemRow: View {
    let item: ActionItem
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.footnote)
                    .lineLimit(2)

                if item.isOverdue {
                    Text("Overdue")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if let dueDate = item.formattedDueDate {
                    Text(dueDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    WatchHomeView()
}
