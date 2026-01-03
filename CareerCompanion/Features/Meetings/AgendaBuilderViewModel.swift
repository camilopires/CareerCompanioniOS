import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the agenda builder
@MainActor
final class AgendaBuilderViewModel: ObservableObject {

    // MARK: - Properties

    let meeting: Meeting

    @Published var agendaItems: [AgendaItem] = []
    @Published var carriedOverItems: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // Meeting prep fields
    @Published var thisWeekGoals: [String] = []
    @Published var thisWeekProgress: [String] = []
    @Published var keyMetrics: [String] = []
    @Published var meetingNotes: String = ""

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }
    private var sdAgendaItems: [UUID: SDAgendaItem] = [:]
    private var sdMeeting: SDMeeting?

    // MARK: - Initialization

    init(meeting: Meeting) {
        self.meeting = meeting
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        // Demo mode - return empty for now
        if AppSettings.shared.isDemoMode {
            agendaItems = []
            carriedOverItems = []
            isLoading = false
            return
        }

        do {
            // Find the SDMeeting
            let meetingID = meeting.id
            let meetingPredicate = #Predicate<SDMeeting> { $0.id == meetingID }
            var descriptor = FetchDescriptor<SDMeeting>(predicate: meetingPredicate)
            descriptor.fetchLimit = 1
            if let foundMeeting = try context.fetch(descriptor).first {
                sdMeeting = foundMeeting

                // Get agenda items from the meeting relationship
                let items = foundMeeting.agendaItems.sorted { $0.order < $1.order }
                agendaItems = items.map { $0.toAgendaItem() }
                sdAgendaItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

                // Load meeting prep fields
                thisWeekGoals = foundMeeting.thisWeekGoals
                thisWeekProgress = foundMeeting.thisWeekProgress
                keyMetrics = foundMeeting.keyMetrics
                meetingNotes = foundMeeting.notes
            }

            // Load incomplete action items from previous meetings
            let openPredicate = #Predicate<SDActionItem> { item in
                item.statusRaw != "completed"
            }
            let actionDescriptor = FetchDescriptor<SDActionItem>(predicate: openPredicate)
            let allOpenItems = try context.fetch(actionDescriptor)
            carriedOverItems = allOpenItems
                .filter { $0.meeting?.id != meeting.id }
                .map { $0.toActionItem() }

        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Agenda Management

    func addItem(title: String) async {
        let newItem = AgendaItem(
            meetingID: meeting.id,
            title: title,
            order: agendaItems.count
        )

        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            agendaItems.append(newItem)
            Theme.lightHaptic()
            return
        }

        do {
            let sdItem = SDAgendaItem(
                id: newItem.id,
                meeting: sdMeeting,
                title: newItem.title,
                notes: newItem.notes,
                isCompleted: newItem.isCompleted,
                order: newItem.order,
                createdAt: newItem.createdAt
            )
            context.insert(sdItem)
            try DataManager.shared.save()

            sdAgendaItems[sdItem.id] = sdItem
            agendaItems.append(newItem)
            Theme.lightHaptic()
        } catch {
            self.error = error
        }
    }

    func updateItem(_ item: AgendaItem) async {
        if AppSettings.shared.isDemoMode {
            if let index = agendaItems.firstIndex(where: { $0.id == item.id }) {
                agendaItems[index] = item
            }
            return
        }

        do {
            if let sdItem = sdAgendaItems[item.id] {
                sdItem.update(from: item)
                try DataManager.shared.save()
            }

            if let index = agendaItems.firstIndex(where: { $0.id == item.id }) {
                agendaItems[index] = item
            }
        } catch {
            self.error = error
        }
    }

    func deleteItems(at offsets: IndexSet) async {
        let itemsToDelete = offsets.map { agendaItems[$0] }

        for item in itemsToDelete {
            if AppSettings.shared.isDemoMode {
                agendaItems.removeAll { $0.id == item.id }
                continue
            }

            do {
                if let sdItem = sdAgendaItems[item.id] {
                    context.delete(sdItem)
                    try DataManager.shared.save()
                    sdAgendaItems.removeValue(forKey: item.id)
                }
                agendaItems.removeAll { $0.id == item.id }
            } catch {
                self.error = error
            }
        }

        // Reorder remaining items
        await reorderItems()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        agendaItems.move(fromOffsets: source, toOffset: destination)

        Task {
            await reorderItems()
        }
    }

    func addTemplate(_ template: AgendaTemplate) async {
        await addItem(title: template.title)
    }

    private func reorderItems() async {
        for (index, var item) in agendaItems.enumerated() {
            if item.order != index {
                item.order = index
                await updateItem(item)
            }
        }
    }

    // MARK: - Meeting Prep Fields

    func addGoal(_ goal: String) {
        guard !goal.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        thisWeekGoals.append(goal)
        savePrepFields()
        Theme.lightHaptic()
    }

    func removeGoal(at index: Int) {
        guard thisWeekGoals.indices.contains(index) else { return }
        thisWeekGoals.remove(at: index)
        savePrepFields()
    }

    func addProgress(_ progress: String) {
        guard !progress.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        thisWeekProgress.append(progress)
        savePrepFields()
        Theme.lightHaptic()
    }

    func removeProgress(at index: Int) {
        guard thisWeekProgress.indices.contains(index) else { return }
        thisWeekProgress.remove(at: index)
        savePrepFields()
    }

    func addMetric(_ metric: String) {
        guard !metric.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        keyMetrics.append(metric)
        savePrepFields()
        Theme.lightHaptic()
    }

    func removeMetric(at index: Int) {
        guard keyMetrics.indices.contains(index) else { return }
        keyMetrics.remove(at: index)
        savePrepFields()
    }

    func updateMeetingNotes(_ notes: String) {
        meetingNotes = notes
        savePrepFields()
    }

    private func savePrepFields() {
        guard !AppSettings.shared.isDemoMode else { return }

        do {
            if let sdMeeting = sdMeeting {
                sdMeeting.thisWeekGoals = thisWeekGoals
                sdMeeting.thisWeekProgress = thisWeekProgress
                sdMeeting.keyMetrics = keyMetrics
                sdMeeting.notes = meetingNotes
                sdMeeting.updatedAt = Date()
                try DataManager.shared.save()
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Export

    func exportAgenda(format: ExportFormat) -> String {
        switch format {
        case .slack:
            return formatForSlack()
        case .teams:
            return formatForTeams()
        case .markdown:
            return formatAsMarkdown()
        case .plainText:
            return formatAsPlainText()
        default:
            return formatAsPlainText()
        }
    }

    private func formatForSlack() -> String {
        var output = "*1:1 Agenda - \(meeting.formattedDate)*\n\n"

        if !carriedOverItems.isEmpty {
            output += ":arrow_right_hook: *Action Items to Review*\n"
            for item in carriedOverItems {
                output += "• \(item.title)\n"
            }
            output += "\n"
        }

        output += ":clipboard: *Agenda*\n"
        for (index, item) in agendaItems.enumerated() {
            output += "\(index + 1). \(item.title)\n"
        }

        return output
    }

    private func formatForTeams() -> String {
        var output = "**1:1 Agenda - \(meeting.formattedDate)**\n\n"

        if !carriedOverItems.isEmpty {
            output += "**Action Items to Review**\n"
            for item in carriedOverItems {
                output += "- \(item.title)\n"
            }
            output += "\n"
        }

        output += "**Agenda**\n"
        for (index, item) in agendaItems.enumerated() {
            output += "\(index + 1). \(item.title)\n"
        }

        return output
    }

    private func formatAsMarkdown() -> String {
        var output = "# 1:1 Agenda - \(meeting.formattedDate)\n\n"

        if !carriedOverItems.isEmpty {
            output += "## Action Items to Review\n"
            for item in carriedOverItems {
                output += "- [ ] \(item.title)\n"
            }
            output += "\n"
        }

        output += "## Agenda\n"
        for (index, item) in agendaItems.enumerated() {
            output += "\(index + 1). \(item.title)\n"
        }

        return output
    }

    private func formatAsPlainText() -> String {
        var output = "1:1 Agenda - \(meeting.formattedDate)\n\n"

        if !carriedOverItems.isEmpty {
            output += "Action Items to Review:\n"
            for item in carriedOverItems {
                output += "  - \(item.title)\n"
            }
            output += "\n"
        }

        output += "Agenda:\n"
        for (index, item) in agendaItems.enumerated() {
            output += "  \(index + 1). \(item.title)\n"
        }

        return output
    }
}
