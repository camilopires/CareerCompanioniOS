import WidgetKit
import SwiftUI

// MARK: - Career Goals Widget

struct CareerGoalsWidget: Widget {
    let kind: String = "CareerGoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareerGoalsProvider()) { entry in
            CareerGoalsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Career Goals")
        .description("Track progress on your career goals.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Timeline Provider

struct CareerGoalsProvider: TimelineProvider {
    private var placeholderGoals: [CareerGoal] {
        [
            CareerGoal(
                title: "Become Senior Engineer",
                goalDescription: "Develop skills for promotion",
                category: .technical,
                status: .inProgress,
                priority: .primary,
                progress: 45,
                skills: ["System Design", "Leadership"]
            ),
            CareerGoal(
                title: "Improve Public Speaking",
                goalDescription: "Present at conferences",
                category: .communication,
                status: .inProgress,
                priority: .secondary,
                progress: 30,
                skills: ["Presentation"]
            )
        ]
    }

    func placeholder(in context: Context) -> CareerGoalsEntry {
        CareerGoalsEntry(
            date: Date(),
            goals: placeholderGoals,
            overallProgress: 0.45
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CareerGoalsEntry) -> Void) {
        let entry = CareerGoalsEntry(
            date: Date(),
            goals: placeholderGoals,
            overallProgress: 0.45
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareerGoalsEntry>) -> Void) {
        Task {
            do {
                let goals: [CareerGoal] = try await CloudKitManager.shared.fetch(
                    predicate: NSPredicate(format: "status == %@ OR status == %@", GoalStatus.inProgress.rawValue, GoalStatus.notStarted.rawValue),
                    sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)]
                )

                let activeGoals = goals.filter { $0.isActive }
                let overallProgress: Double
                if activeGoals.isEmpty {
                    overallProgress = 0
                } else {
                    let total = activeGoals.reduce(0) { $0 + $1.progress }
                    overallProgress = Double(total) / Double(activeGoals.count * 100)
                }

                let entry = CareerGoalsEntry(
                    date: Date(),
                    goals: Array(activeGoals.prefix(3)),
                    overallProgress: overallProgress
                )

                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = CareerGoalsEntry(date: Date(), goals: [], overallProgress: 0)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            }
        }
    }
}

// MARK: - Entry

struct CareerGoalsEntry: TimelineEntry {
    let date: Date
    let goals: [CareerGoal]
    let overallProgress: Double
}

// MARK: - Widget View

struct CareerGoalsWidgetView: View {
    let entry: CareerGoalsEntry

    var body: some View {
        HStack(spacing: 16) {
            // Overall progress
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.overallProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.overallProgress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(width: 70, height: 70)

                Text("Overall")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Goals list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Career Goals")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if entry.goals.isEmpty {
                    Text("No active goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.goals) { goal in
                        HStack(spacing: 8) {
                            // Mini progress ring
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 2)

                                Circle()
                                    .trim(from: 0, to: goal.progressPercentage)
                                    .stroke(goalColor(for: goal), lineWidth: 2)
                                    .rotationEffect(.degrees(-90))
                            }
                            .frame(width: 16, height: 16)

                            Text(goal.title)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text("\(goal.progress)%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func goalColor(for goal: CareerGoal) -> Color {
        switch goal.status {
        case .achieved: return .green
        case .inProgress: return goal.category.color
        case .paused: return .orange
        case .notStarted: return .secondary
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    CareerGoalsWidget()
} timeline: {
    CareerGoalsEntry(
        date: Date(),
        goals: [
            CareerGoal(
                title: "Become Senior Engineer",
                goalDescription: "Develop skills for promotion",
                category: .technical,
                status: .inProgress,
                priority: .primary,
                progress: 45,
                skills: ["System Design", "Leadership"]
            ),
            CareerGoal(
                title: "Improve Public Speaking",
                goalDescription: "Present at conferences",
                category: .communication,
                status: .inProgress,
                priority: .secondary,
                progress: 30,
                skills: ["Presentation"]
            )
        ],
        overallProgress: 0.45
    )
}
