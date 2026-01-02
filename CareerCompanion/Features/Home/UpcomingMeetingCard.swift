import SwiftUI

/// Card showing the next upcoming 1:1 meeting
struct UpcomingMeetingCard: View {
    let meeting: Meeting
    let manager: Manager?

    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Next 1:1")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: MeetingsListView()) {
                    Text("All Meetings")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Card content
            TappableCard(action: {
                // Navigate to meeting preparation
            }) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        // Manager info
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            if let manager {
                                Text("with \(manager.name)")
                                    .font(Typography.body)
                                    .foregroundStyle(Colors.textPrimary)
                            }

                            Text(meeting.formattedDate)
                                .font(Typography.callout)
                                .foregroundStyle(Colors.textSecondary)
                        }

                        Spacer()

                        // Countdown
                        CountdownView(targetDate: meeting.date, now: now)
                    }

                    // Quick actions
                    HStack(spacing: Spacing.md) {
                        NavigationLink(destination: AgendaBuilderView(meeting: meeting)) {
                            Label("Prepare Agenda", systemImage: "list.bullet.clipboard")
                                .font(Typography.callout)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Colors.textTertiary)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}

// MARK: - Countdown View

private struct CountdownView: View {
    let targetDate: Date
    let now: Date

    private var timeRemaining: (days: Int, hours: Int, minutes: Int) {
        let interval = targetDate.timeIntervalSince(now)
        guard interval > 0 else { return (0, 0, 0) }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        return (days, hours, minutes)
    }

    private var displayText: String {
        let (days, hours, minutes) = timeRemaining

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now"
        }
    }

    private var isImminent: Bool {
        let (days, hours, _) = timeRemaining
        return days == 0 && hours < 2
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(displayText)
                .font(Typography.timer)
                .foregroundStyle(isImminent ? Colors.warning : Color.accentColor)

            Text("until")
                .font(Typography.caption2)
                .foregroundStyle(Colors.textTertiary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                .fill(isImminent ? Colors.warning.opacity(0.1) : Color.accentColor.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayText) until meeting")
    }
}

// MARK: - No Meeting Card

struct NoUpcomingMeetingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Next 1:1")
                .font(Typography.headline)

            Card {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("No upcoming 1:1 scheduled")
                            .font(Typography.body)
                            .foregroundStyle(Colors.textPrimary)

                        Text("Schedule your next meeting to stay connected")
                            .font(Typography.callout)
                            .foregroundStyle(Colors.textSecondary)
                    }

                    Spacer()

                    Button(action: {
                        // Create new meeting
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel("Schedule meeting")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Upcoming Meeting Card") {
    let previewManager = Manager(name: "Sarah Johnson", email: "sarah@company.com")

    return NavigationStack {
        VStack(spacing: Spacing.lg) {
            UpcomingMeetingCard(
                meeting: Meeting(
                    managerID: previewManager.id,
                    date: Date().addingTimeInterval(86400 * 2) // 2 days
                ),
                manager: previewManager
            )

            UpcomingMeetingCard(
                meeting: Meeting(
                    managerID: previewManager.id,
                    date: Date().addingTimeInterval(3600) // 1 hour
                ),
                manager: previewManager
            )

            NoUpcomingMeetingCard()
        }
        .padding()
    }
}
