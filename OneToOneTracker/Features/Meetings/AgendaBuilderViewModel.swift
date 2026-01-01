import Foundation
import SwiftUI

/// ViewModel for the agenda builder
@MainActor
final class AgendaBuilderViewModel: ObservableObject {

    // MARK: - Properties

    let meeting: Meeting

    @Published var agendaItems: [AgendaItem] = []
    @Published var carriedOverItems: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Initialization

    init(meeting: Meeting) {
        self.meeting = meeting
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        do {
            // Load agenda items for this meeting
            let items: [AgendaItem] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "meetingRef == %@", meeting.recordID),
                sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)]
            )
            agendaItems = items

            // Load incomplete action items from previous meetings
            let actionItems: [ActionItem] = try await CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "status != %@", ActionItemStatus.completed.rawValue)
            )
            carriedOverItems = actionItems.filter { $0.meetingID != meeting.id }

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

        do {
            let saved = try await CloudKitManager.shared.save(newItem)
            agendaItems.append(saved)
            Theme.lightHaptic()
        } catch {
            self.error = error
        }
    }

    func updateItem(_ item: AgendaItem) async {
        do {
            let saved = try await CloudKitManager.shared.save(item)
            if let index = agendaItems.firstIndex(where: { $0.id == saved.id }) {
                agendaItems[index] = saved
            }
        } catch {
            self.error = error
        }
    }

    func deleteItems(at offsets: IndexSet) async {
        let itemsToDelete = offsets.map { agendaItems[$0] }

        for item in itemsToDelete {
            do {
                try await CloudKitManager.shared.delete(item)
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
