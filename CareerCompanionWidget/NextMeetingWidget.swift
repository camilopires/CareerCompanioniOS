import WidgetKit
import SwiftUI

// MARK: - Next Meeting Widget

struct NextMeetingWidget: Widget {
    let kind: String = "NextMeetingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextMeetingProvider()) { entry in
            NextMeetingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next 1:1")
        .description("See when your next 1:1 meeting is scheduled.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct NextMeetingProvider: TimelineProvider {
    private var placeholderMeeting: Meeting {
        Meeting(
            managerID: UUID(),
            date: Date().addingTimeInterval(86400 * 2) // 2 days from now
        )
    }

    func placeholder(in context: Context) -> NextMeetingEntry {
        NextMeetingEntry(
            date: Date(),
            meeting: placeholderMeeting,
            managerName: "Sarah"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextMeetingEntry) -> Void) {
        let entry = NextMeetingEntry(
            date: Date(),
            meeting: placeholderMeeting,
            managerName: "Sarah"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextMeetingEntry>) -> Void) {
        Task {
            do {
                let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                    predicate: NSPredicate(format: "status == %@ AND date > %@", MeetingStatus.scheduled.rawValue, Date() as CVarArg),
                    sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
                    limit: 1
                )

                let managers: [Manager] = try await CloudKitManager.shared.fetch()
                let manager = managers.first

                let entry = NextMeetingEntry(
                    date: Date(),
                    meeting: meetings.first,
                    managerName: manager?.name
                )

                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = NextMeetingEntry(date: Date(), meeting: nil, managerName: nil)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Entry

struct NextMeetingEntry: TimelineEntry {
    let date: Date
    let meeting: Meeting?
    let managerName: String?
}

// MARK: - Widget View

struct NextMeetingWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NextMeetingEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallNextMeetingView(entry: entry)
        case .accessoryCircular:
            CircularNextMeetingView(entry: entry)
        case .accessoryRectangular:
            RectangularNextMeetingView(entry: entry)
        default:
            SmallNextMeetingView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallNextMeetingView: View {
    let entry: NextMeetingEntry

    private var countdownText: String {
        guard let meeting = entry.meeting else { return "No meeting" }
        let interval = meeting.date.timeIntervalSince(entry.date)
        guard interval > 0 else { return "Now" }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Next 1:1")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            if let meeting = entry.meeting {
                VStack(alignment: .leading, spacing: 4) {
                    Text(countdownText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    if let name = entry.managerName {
                        Text("with \(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No upcoming 1:1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Lock Screen Circular Widget

struct CircularNextMeetingView: View {
    let entry: NextMeetingEntry

    private var daysUntil: Int {
        guard let meeting = entry.meeting else { return 0 }
        let interval = meeting.date.timeIntervalSince(entry.date)
        return max(0, Int(interval) / 86400)
    }

    var body: some View {
        if entry.meeting != nil {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 0) {
                    Text("\(daysUntil)")
                        .font(.system(size: 24, weight: .bold))

                    Text("days")
                        .font(.system(size: 10))
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()

                Image(systemName: "person.2")
                    .font(.title2)
            }
        }
    }
}

// MARK: - Lock Screen Rectangular Widget

struct RectangularNextMeetingView: View {
    let entry: NextMeetingEntry

    var body: some View {
        if let meeting = entry.meeting {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next 1:1")
                        .font(.caption2)
                        .fontWeight(.semibold)

                    Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)

                    if let name = entry.managerName {
                        Text("with \(name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "person.2.fill")
            }
        } else {
            HStack {
                Text("No upcoming 1:1")
                    .font(.caption)

                Spacer()

                Image(systemName: "person.2")
            }
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NextMeetingWidget()
} timeline: {
    NextMeetingEntry(
        date: Date(),
        meeting: Meeting(
            managerID: UUID(),
            date: Date().addingTimeInterval(86400 * 2 + 3600 * 5)
        ),
        managerName: "Sarah"
    )
}

#Preview(as: .accessoryCircular) {
    NextMeetingWidget()
} timeline: {
    NextMeetingEntry(
        date: Date(),
        meeting: Meeting(
            managerID: UUID(),
            date: Date().addingTimeInterval(86400 * 3)
        ),
        managerName: "Sarah"
    )
}
