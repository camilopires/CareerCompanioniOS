import WidgetKit
import SwiftUI

// MARK: - Action Items Widget

struct ActionItemsWidget: Widget {
    let kind: String = "ActionItemsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActionItemsProvider()) { entry in
            ActionItemsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Action Items")
        .description("View and track your open action items.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct ActionItemsProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActionItemsEntry {
        ActionItemsEntry(
            date: Date(),
            actionItems: ActionItem.samples.filter { $0.status != .completed },
            openCount: 4,
            overdueCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ActionItemsEntry) -> Void) {
        let entry = ActionItemsEntry(
            date: Date(),
            actionItems: ActionItem.samples.filter { $0.status != .completed },
            openCount: 4,
            overdueCount: 1
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActionItemsEntry>) -> Void) {
        Task {
            do {
                let items: [ActionItem] = try await CloudKitManager.shared.fetch(
                    predicate: NSPredicate(format: "status != %@", ActionItemStatus.completed.rawValue),
                    sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)]
                )

                let openItems = items.filter { $0.status != .completed }
                let overdueItems = items.filter { $0.isOverdue }

                let entry = ActionItemsEntry(
                    date: Date(),
                    actionItems: Array(openItems.prefix(5)),
                    openCount: openItems.count,
                    overdueCount: overdueItems.count
                )

                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = ActionItemsEntry(
                    date: Date(),
                    actionItems: [],
                    openCount: 0,
                    overdueCount: 0
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Entry

struct ActionItemsEntry: TimelineEntry {
    let date: Date
    let actionItems: [ActionItem]
    let openCount: Int
    let overdueCount: Int
}

// MARK: - Widget View

struct ActionItemsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ActionItemsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallActionItemsView(entry: entry)
        case .systemMedium:
            MediumActionItemsView(entry: entry)
        case .systemLarge:
            LargeActionItemsView(entry: entry)
        default:
            SmallActionItemsView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallActionItemsView: View {
    let entry: ActionItemsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(Color.accentColor)
                Text("Action Items")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.openCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("open items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.overdueCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("\(entry.overdueCount) overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget

struct MediumActionItemsView: View {
    let entry: ActionItemsEntry

    var body: some View {
        HStack(spacing: 16) {
            // Count section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(Color.accentColor)
                    Text("Action Items")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(entry.openCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                if entry.overdueCount > 0 {
                    Text("\(entry.overdueCount) overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 80)

            Divider()

            // Items list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.actionItems.prefix(3)) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .strokeBorder(item.isOverdue ? Color.red : Color.secondary, lineWidth: 1.5)
                            .frame(width: 14, height: 14)

                        Text(item.title)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        if let date = item.formattedDueDate {
                            Text(date)
                                .font(.caption2)
                                .foregroundStyle(item.isOverdue ? .red : .secondary)
                        }
                    }
                }

                if entry.actionItems.count > 3 {
                    Text("+\(entry.openCount - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Large Widget

struct LargeActionItemsView: View {
    let entry: ActionItemsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(Color.accentColor)
                Text("Action Items")
                    .font(.headline)

                Spacer()

                Text("\(entry.openCount) open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Items list
            if entry.actionItems.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.actionItems.prefix(5)) { item in
                    HStack(spacing: 10) {
                        Circle()
                            .strokeBorder(item.isOverdue ? Color.red : Color.secondary, lineWidth: 2)
                            .frame(width: 18, height: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                if item.priority == .high {
                                    Label("High", systemImage: "arrow.up")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }

                                if let date = item.formattedDueDate {
                                    Label(date, systemImage: "calendar")
                                        .font(.caption2)
                                        .foregroundStyle(item.isOverdue ? .red : .secondary)
                                }
                            }
                        }

                        Spacer()
                    }

                    if item.id != entry.actionItems.prefix(5).last?.id {
                        Divider()
                    }
                }

                Spacer()

                if entry.openCount > 5 {
                    Text("Open app to see all \(entry.openCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ActionItemsWidget()
} timeline: {
    ActionItemsEntry(
        date: Date(),
        actionItems: ActionItem.samples,
        openCount: 4,
        overdueCount: 1
    )
}

#Preview(as: .systemMedium) {
    ActionItemsWidget()
} timeline: {
    ActionItemsEntry(
        date: Date(),
        actionItems: ActionItem.samples,
        openCount: 4,
        overdueCount: 1
    )
}

#Preview(as: .systemLarge) {
    ActionItemsWidget()
} timeline: {
    ActionItemsEntry(
        date: Date(),
        actionItems: ActionItem.samples,
        openCount: 4,
        overdueCount: 1
    )
}
