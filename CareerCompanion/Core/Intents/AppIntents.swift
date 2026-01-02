import AppIntents
import Foundation

// MARK: - Check Next Meeting Intent

struct CheckNextMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Next 1:1"
    static var description = IntentDescription("Check when your next 1:1 meeting is scheduled")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let nextMeeting = await fetchNextMeeting()

        if let meeting = nextMeeting {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            let managerName = await fetchManagerName(for: meeting.managerID)
            let dateString = dateFormatter.string(from: meeting.date)

            return .result(dialog: "Your next 1:1 with \(managerName) is on \(dateString).")
        } else {
            return .result(dialog: "You don't have any upcoming 1:1 meetings scheduled.")
        }
    }

    private func fetchNextMeeting() async -> Meeting? {
        if AppSettings.shared.isDemoMode {
            return DemoDataProvider.meetings
                .filter { $0.status == .scheduled && $0.date > Date() }
                .sorted { $0.date < $1.date }
                .first
        }

        do {
            let meetings: [Meeting] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status == %@ AND date > %@",
                                       MeetingStatus.scheduled.rawValue,
                                       Date() as NSDate),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)]
            )
            return meetings.first
        } catch {
            return nil
        }
    }

    private func fetchManagerName(for managerID: UUID) async -> String {
        if AppSettings.shared.isDemoMode {
            return DemoDataProvider.managers.first { $0.id == managerID }?.name ?? "your manager"
        }

        do {
            let managers: [Manager] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "id == %@", managerID.uuidString)
            )
            return managers.first?.name ?? "your manager"
        } catch {
            return "your manager"
        }
    }
}

// MARK: - Check Action Items Intent

struct CheckActionItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Action Items"
    static var description = IntentDescription("Check your open action items")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let items = await fetchOpenActionItems()

        if items.isEmpty {
            return .result(dialog: "You have no open action items. Great job staying on top of things!")
        } else if items.count == 1 {
            return .result(dialog: "You have 1 open action item: \(items.first!.title)")
        } else {
            let highPriority = items.filter { $0.priority == .high }.count
            let overdue = items.filter { $0.isOverdue }.count

            var message = "You have \(items.count) open action items."
            if highPriority > 0 {
                message += " \(highPriority) are high priority."
            }
            if overdue > 0 {
                message += " \(overdue) are overdue."
            }

            return .result(dialog: "\(message)")
        }
    }

    private func fetchOpenActionItems() async -> [ActionItem] {
        if AppSettings.shared.isDemoMode {
            return DemoDataProvider.actionItems.filter { $0.status != .completed }
        }

        do {
            return try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status != %@", ActionItemStatus.completed.rawValue)
            )
        } catch {
            return []
        }
    }
}

// MARK: - Add Action Item Intent

struct AddActionItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Action Item"
    static var description = IntentDescription("Add a new action item to track")

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Priority", default: .medium)
    var priority: ActionItemPriorityEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Add action item \(\.$title) with \(\.$priority) priority")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let newItem = ActionItem(
            title: title,
            priority: priority.toPriority
        )

        if !AppSettings.shared.isDemoMode {
            do {
                try await CloudKitManager.shared.save(newItem)
            } catch {
                return .result(dialog: "Failed to add action item. Please try again.")
            }
        }

        return .result(dialog: "Added action item: \(title)")
    }
}

// MARK: - Log Achievement Intent

struct LogAchievementIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Achievement"
    static var description = IntentDescription("Log a new achievement")

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Description")
    var achievementDescription: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log achievement \(\.$title)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let achievement = Achievement(
            title: title,
            achievementDescription: achievementDescription ?? "",
            dateAchieved: Date()
        )

        if !AppSettings.shared.isDemoMode {
            do {
                try await CloudKitManager.shared.save(achievement)
            } catch {
                return .result(dialog: "Failed to log achievement. Please try again.")
            }
        }

        return .result(dialog: "Logged achievement: \(title)")
    }
}

// MARK: - Start Meeting Intent

struct StartMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start 1:1 Meeting"
    static var description = IntentDescription("Open the app to start your 1:1 meeting")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // App will open - navigation handled by the app
        return .result()
    }
}

// MARK: - Priority Entity for Intents

enum ActionItemPriorityEntity: String, AppEnum {
    case low
    case medium
    case high

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Priority"
    }

    static var caseDisplayRepresentations: [ActionItemPriorityEntity: DisplayRepresentation] {
        [
            .low: "Low",
            .medium: "Medium",
            .high: "High"
        ]
    }

    var toPriority: Priority {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}

// MARK: - App Shortcuts Provider

struct OneToOneShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckNextMeetingIntent(),
            phrases: [
                "When is my next 1:1 in \(.applicationName)",
                "Check my next one on one in \(.applicationName)",
                "When is my next meeting with my manager in \(.applicationName)"
            ],
            shortTitle: "Next 1:1",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: CheckActionItemsIntent(),
            phrases: [
                "Check my action items in \(.applicationName)",
                "What are my action items in \(.applicationName)",
                "Show my tasks in \(.applicationName)"
            ],
            shortTitle: "Action Items",
            systemImageName: "checklist"
        )

        AppShortcut(
            intent: AddActionItemIntent(),
            phrases: [
                "Add action item in \(.applicationName)",
                "Create a task in \(.applicationName)"
            ],
            shortTitle: "Add Action Item",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: LogAchievementIntent(),
            phrases: [
                "Log achievement in \(.applicationName)",
                "Record an achievement in \(.applicationName)"
            ],
            shortTitle: "Log Achievement",
            systemImageName: "star.circle"
        )

        AppShortcut(
            intent: StartMeetingIntent(),
            phrases: [
                "Start my 1:1 in \(.applicationName)",
                "Begin one on one meeting in \(.applicationName)"
            ],
            shortTitle: "Start 1:1",
            systemImageName: "play.circle"
        )
    }
}
