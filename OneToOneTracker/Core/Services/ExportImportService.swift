import Foundation
import UniformTypeIdentifiers

// MARK: - Export Data Container

/// Container for all exportable app data
struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let exportVersion: Int
    let managers: [Manager]
    let meetings: [Meeting]
    let actionItems: [ActionItem]
    let careerGoals: [CareerGoal]
    let achievements: [Achievement]
    let agendaItems: [AgendaItem]

    static let currentExportVersion = 1

    init(
        managers: [Manager],
        meetings: [Meeting],
        actionItems: [ActionItem],
        careerGoals: [CareerGoal],
        achievements: [Achievement],
        agendaItems: [AgendaItem]
    ) {
        self.exportDate = Date()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.exportVersion = Self.currentExportVersion
        self.managers = managers
        self.meetings = meetings
        self.actionItems = actionItems
        self.careerGoals = careerGoals
        self.achievements = achievements
        self.agendaItems = agendaItems
    }
}

// MARK: - Export Format

enum DataExportFormat: String, CaseIterable, Identifiable {
    case json
    case csv

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .json: return "JSON (Full Backup)"
        case .csv: return "CSV (Spreadsheet)"
        }
    }

    var icon: String {
        switch self {
        case .json: return "doc.badge.gearshape"
        case .csv: return "tablecells"
        }
    }

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var utType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        }
    }

    var description: String {
        switch self {
        case .json: return "Complete backup including all data. Use for restoring or transferring to another device."
        case .csv: return "Export meetings and action items for analysis in spreadsheet apps."
        }
    }
}

// MARK: - Import Result

struct ImportResult {
    let managersImported: Int
    let meetingsImported: Int
    let actionItemsImported: Int
    let goalsImported: Int
    let achievementsImported: Int
    let agendaItemsImported: Int
    let errors: [String]

    var totalImported: Int {
        managersImported + meetingsImported + actionItemsImported +
        goalsImported + achievementsImported + agendaItemsImported
    }

    var hasErrors: Bool {
        !errors.isEmpty
    }

    var summary: String {
        var parts: [String] = []
        if managersImported > 0 { parts.append("\(managersImported) manager(s)") }
        if meetingsImported > 0 { parts.append("\(meetingsImported) meeting(s)") }
        if actionItemsImported > 0 { parts.append("\(actionItemsImported) action item(s)") }
        if goalsImported > 0 { parts.append("\(goalsImported) goal(s)") }
        if achievementsImported > 0 { parts.append("\(achievementsImported) achievement(s)") }
        if agendaItemsImported > 0 { parts.append("\(agendaItemsImported) agenda item(s)") }

        if parts.isEmpty {
            return "No data imported"
        }
        return "Imported: " + parts.joined(separator: ", ")
    }
}

// MARK: - Conflict Resolution

enum ImportConflictResolution: String, CaseIterable, Identifiable {
    case skip
    case replace
    case keepBoth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skip: return "Skip Duplicates"
        case .replace: return "Replace Existing"
        case .keepBoth: return "Keep Both"
        }
    }

    var description: String {
        switch self {
        case .skip: return "Keep existing data, ignore duplicates from import"
        case .replace: return "Replace existing data with imported data"
        case .keepBoth: return "Create new entries for imported duplicates"
        }
    }
}

// MARK: - Export Import Service

@MainActor
final class ExportImportService: ObservableObject {
    static let shared = ExportImportService()

    @Published var isExporting = false
    @Published var isImporting = false
    @Published var progress: Double = 0
    @Published var statusMessage = ""

    private let cloudKitManager = CloudKitManager.shared

    private init() {}

    // MARK: - Export

    /// Export all data to JSON format
    func exportToJSON() async throws -> Data {
        isExporting = true
        progress = 0
        statusMessage = "Fetching data..."

        defer {
            isExporting = false
            progress = 1.0
            statusMessage = ""
        }

        // Fetch all data from CloudKit
        progress = 0.1
        let managers: [Manager] = try await cloudKitManager.fetch()

        progress = 0.2
        let meetings: [Meeting] = try await cloudKitManager.fetch()

        progress = 0.4
        let actionItems: [ActionItem] = try await cloudKitManager.fetch()

        progress = 0.6
        let careerGoals: [CareerGoal] = try await cloudKitManager.fetch()

        progress = 0.7
        let achievements: [Achievement] = try await cloudKitManager.fetch()

        progress = 0.8
        let agendaItems: [AgendaItem] = try await cloudKitManager.fetch()

        progress = 0.9
        statusMessage = "Creating export file..."

        let exportData = ExportData(
            managers: managers,
            meetings: meetings,
            actionItems: actionItems,
            careerGoals: careerGoals,
            achievements: achievements,
            agendaItems: agendaItems
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    /// Export meetings and action items to CSV format
    func exportToCSV() async throws -> Data {
        isExporting = true
        progress = 0
        statusMessage = "Fetching data..."

        defer {
            isExporting = false
            progress = 1.0
            statusMessage = ""
        }

        progress = 0.2
        let managers: [Manager] = try await cloudKitManager.fetch()
        let managerLookup = Dictionary(uniqueKeysWithValues: managers.map { ($0.id, $0) })

        progress = 0.4
        let meetings: [Meeting] = try await cloudKitManager.fetch()

        progress = 0.6
        let actionItems: [ActionItem] = try await cloudKitManager.fetch()

        progress = 0.8
        statusMessage = "Creating CSV..."

        var csv = "Type,ID,Title/Description,Date,Status,Priority,Manager/Owner,Notes\n"

        // Add meetings
        for meeting in meetings.sorted(by: { $0.date > $1.date }) {
            let managerName = managerLookup[meeting.managerID]?.name ?? "Unknown"
            let row = [
                "Meeting",
                meeting.id.uuidString,
                "1:1 with \(managerName)",
                formatDate(meeting.date),
                meeting.status.displayName,
                "",
                managerName,
                escapeCSV(meeting.notes)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        // Add action items
        for item in actionItems.sorted(by: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }) {
            let row = [
                "Action Item",
                item.id.uuidString,
                escapeCSV(item.title),
                item.dueDate.map { formatDate($0) } ?? "",
                item.status.displayName,
                item.priority.displayName,
                item.owner.displayName,
                escapeCSV(item.itemDescription)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        return csv.data(using: .utf8) ?? Data()
    }

    /// Generate export filename
    func generateFilename(format: DataExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "CareerCompanion-\(dateString).\(format.fileExtension)"
    }

    // MARK: - Import

    /// Import data from JSON file
    func importFromJSON(
        data: Data,
        conflictResolution: ImportConflictResolution
    ) async throws -> ImportResult {
        isImporting = true
        progress = 0
        statusMessage = "Reading file..."

        defer {
            isImporting = false
            progress = 1.0
            statusMessage = ""
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: data)

        progress = 0.1
        statusMessage = "Checking for duplicates..."

        // Fetch existing data to check for conflicts
        let existingManagers: [Manager] = try await cloudKitManager.fetch()
        let existingMeetings: [Meeting] = try await cloudKitManager.fetch()
        let existingActionItems: [ActionItem] = try await cloudKitManager.fetch()
        let existingGoals: [CareerGoal] = try await cloudKitManager.fetch()
        let existingAchievements: [Achievement] = try await cloudKitManager.fetch()
        let existingAgendaItems: [AgendaItem] = try await cloudKitManager.fetch()

        let existingManagerIDs = Set(existingManagers.map { $0.id })
        let existingMeetingIDs = Set(existingMeetings.map { $0.id })
        let existingActionItemIDs = Set(existingActionItems.map { $0.id })
        let existingGoalIDs = Set(existingGoals.map { $0.id })
        let existingAchievementIDs = Set(existingAchievements.map { $0.id })
        let existingAgendaItemIDs = Set(existingAgendaItems.map { $0.id })

        var errors: [String] = []
        var managersImported = 0
        var meetingsImported = 0
        var actionItemsImported = 0
        var goalsImported = 0
        var achievementsImported = 0
        var agendaItemsImported = 0

        progress = 0.2
        statusMessage = "Importing managers..."

        // Import managers
        for manager in exportData.managers {
            let shouldImport = shouldImportItem(
                id: manager.id,
                existingIDs: existingManagerIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importManager = manager
                if conflictResolution == .keepBoth && existingManagerIDs.contains(manager.id) {
                    importManager = Manager(
                        id: UUID(),
                        name: manager.name,
                        email: manager.email,
                        relationshipType: manager.relationshipType,
                        tags: manager.tags,
                        createdAt: manager.createdAt
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importManager)
                    managersImported += 1
                } catch {
                    errors.append("Failed to import manager '\(manager.name)': \(error.localizedDescription)")
                }
            }
        }

        progress = 0.4
        statusMessage = "Importing meetings..."

        // Import meetings
        for meeting in exportData.meetings {
            let shouldImport = shouldImportItem(
                id: meeting.id,
                existingIDs: existingMeetingIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importMeeting = meeting
                if conflictResolution == .keepBoth && existingMeetingIDs.contains(meeting.id) {
                    importMeeting = Meeting(
                        id: UUID(),
                        managerID: meeting.managerID,
                        date: meeting.date,
                        status: meeting.status,
                        perspective: meeting.perspective,
                        meetingType: meeting.meetingType,
                        notes: meeting.notes,
                        wentWell: meeting.wentWell,
                        didntGoWell: meeting.didntGoWell,
                        blockers: meeting.blockers,
                        escalations: meeting.escalations,
                        thisWeekGoals: meeting.thisWeekGoals,
                        thisWeekProgress: meeting.thisWeekProgress,
                        keyMetrics: meeting.keyMetrics,
                        nextWeekGoals: meeting.nextWeekGoals,
                        weekSentiment: meeting.weekSentiment,
                        meetingSentiment: meeting.meetingSentiment,
                        createdAt: meeting.createdAt,
                        updatedAt: meeting.updatedAt
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importMeeting)
                    meetingsImported += 1
                } catch {
                    errors.append("Failed to import meeting: \(error.localizedDescription)")
                }
            }
        }

        progress = 0.6
        statusMessage = "Importing action items..."

        // Import action items
        for item in exportData.actionItems {
            let shouldImport = shouldImportItem(
                id: item.id,
                existingIDs: existingActionItemIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importItem = item
                if conflictResolution == .keepBoth && existingActionItemIDs.contains(item.id) {
                    importItem = ActionItem(
                        id: UUID(),
                        meetingID: item.meetingID,
                        title: item.title,
                        itemDescription: item.itemDescription,
                        dueDate: item.dueDate,
                        priority: item.priority,
                        status: item.status,
                        owner: item.owner,
                        links: item.links,
                        createdAt: item.createdAt,
                        completedAt: item.completedAt,
                        completionNotes: item.completionNotes
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importItem)
                    actionItemsImported += 1
                } catch {
                    errors.append("Failed to import action item '\(item.title)': \(error.localizedDescription)")
                }
            }
        }

        progress = 0.7
        statusMessage = "Importing career goals..."

        // Import career goals
        for goal in exportData.careerGoals {
            let shouldImport = shouldImportItem(
                id: goal.id,
                existingIDs: existingGoalIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importGoal = goal
                if conflictResolution == .keepBoth && existingGoalIDs.contains(goal.id) {
                    importGoal = CareerGoal(
                        id: UUID(),
                        title: goal.title,
                        goalDescription: goal.goalDescription,
                        category: goal.category,
                        targetDate: goal.targetDate,
                        status: goal.status,
                        priority: goal.priority,
                        successMetrics: goal.successMetrics,
                        trackingMethod: goal.trackingMethod,
                        progress: goal.progress,
                        skills: goal.skills,
                        notes: goal.notes,
                        createdAt: goal.createdAt,
                        updatedAt: goal.updatedAt
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importGoal)
                    goalsImported += 1
                } catch {
                    errors.append("Failed to import goal '\(goal.title)': \(error.localizedDescription)")
                }
            }
        }

        progress = 0.8
        statusMessage = "Importing achievements..."

        // Import achievements
        for achievement in exportData.achievements {
            let shouldImport = shouldImportItem(
                id: achievement.id,
                existingIDs: existingAchievementIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importAchievement = achievement
                if conflictResolution == .keepBoth && existingAchievementIDs.contains(achievement.id) {
                    importAchievement = Achievement(
                        id: UUID(),
                        title: achievement.title,
                        achievementDescription: achievement.achievementDescription,
                        dateAchieved: achievement.dateAchieved,
                        impactStatement: achievement.impactStatement,
                        goalIDs: achievement.goalIDs,
                        evidenceLinks: achievement.evidenceLinks,
                        tags: achievement.tags,
                        visibility: achievement.visibility,
                        meetingID: achievement.meetingID,
                        createdAt: achievement.createdAt
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importAchievement)
                    achievementsImported += 1
                } catch {
                    errors.append("Failed to import achievement '\(achievement.title)': \(error.localizedDescription)")
                }
            }
        }

        progress = 0.9
        statusMessage = "Importing agenda items..."

        // Import agenda items
        for agendaItem in exportData.agendaItems {
            let shouldImport = shouldImportItem(
                id: agendaItem.id,
                existingIDs: existingAgendaItemIDs,
                resolution: conflictResolution
            )

            if shouldImport {
                var importAgendaItem = agendaItem
                if conflictResolution == .keepBoth && existingAgendaItemIDs.contains(agendaItem.id) {
                    importAgendaItem = AgendaItem(
                        id: UUID(),
                        meetingID: agendaItem.meetingID,
                        title: agendaItem.title,
                        notes: agendaItem.notes,
                        isCompleted: agendaItem.isCompleted,
                        order: agendaItem.order,
                        createdAt: agendaItem.createdAt
                    )
                }

                do {
                    _ = try await cloudKitManager.save(importAgendaItem)
                    agendaItemsImported += 1
                } catch {
                    errors.append("Failed to import agenda item '\(agendaItem.title)': \(error.localizedDescription)")
                }
            }
        }

        return ImportResult(
            managersImported: managersImported,
            meetingsImported: meetingsImported,
            actionItemsImported: actionItemsImported,
            goalsImported: goalsImported,
            achievementsImported: achievementsImported,
            agendaItemsImported: agendaItemsImported,
            errors: errors
        )
    }

    /// Preview import data without actually importing
    func previewImport(data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }

    // MARK: - Private Helpers

    private func shouldImportItem(
        id: UUID,
        existingIDs: Set<UUID>,
        resolution: ImportConflictResolution
    ) -> Bool {
        let exists = existingIDs.contains(id)

        switch resolution {
        case .skip:
            return !exists
        case .replace:
            return true
        case .keepBoth:
            return true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private func escapeCSV(_ string: String) -> String {
        let needsQuotes = string.contains(",") || string.contains("\"") || string.contains("\n")
        if needsQuotes {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}

// MARK: - Export Data Statistics

extension ExportData {
    var statistics: String {
        var parts: [String] = []
        if !managers.isEmpty { parts.append("\(managers.count) manager(s)") }
        if !meetings.isEmpty { parts.append("\(meetings.count) meeting(s)") }
        if !actionItems.isEmpty { parts.append("\(actionItems.count) action item(s)") }
        if !careerGoals.isEmpty { parts.append("\(careerGoals.count) goal(s)") }
        if !achievements.isEmpty { parts.append("\(achievements.count) achievement(s)") }
        if !agendaItems.isEmpty { parts.append("\(agendaItems.count) agenda item(s)") }

        if parts.isEmpty {
            return "No data"
        }
        return parts.joined(separator: ", ")
    }

    var formattedExportDate: String {
        exportDate.formatted(date: .abbreviated, time: .shortened)
    }
}
