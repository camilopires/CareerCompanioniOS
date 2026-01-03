import Foundation
import UIKit

/// Service for generating beautifully formatted meeting exports
/// Supports multiple templates (prep/summary) and styles (professional/casual/minimal)
final class MeetingExportService {
    static let shared = MeetingExportService()

    private let settings = AppSettings.shared
    private let dividerLine = "─────────────────────────────"

    private init() {}

    // MARK: - Main Export Functions

    /// Generate formatted export text for a meeting
    func generateExport(
        meeting: Meeting,
        template: ExportTemplate,
        managerName: String,
        agendaItems: [AgendaItem] = [],
        actionItems: [ActionItem] = [],
        previousMeeting: Meeting? = nil
    ) -> String {
        let style = settings.exportStyle

        var sections: [String] = []

        // Header is always included
        sections.append(buildHeader(meeting: meeting, managerName: managerName, style: style))

        // Get sections based on template
        let templateSections = template == .prep ? ExportSection.prepSections : ExportSection.summarySections

        for section in templateSections {
            guard section != .header else { continue } // Header already added
            guard settings.isSectionIncludedInExport(section) else { continue }

            if let content = buildSection(
                section,
                meeting: meeting,
                style: style,
                agendaItems: agendaItems,
                actionItems: actionItems,
                previousMeeting: previousMeeting
            ) {
                sections.append(content)
            }
        }

        return sections.joined(separator: "\n\n")
    }

    /// Copy formatted text to clipboard (with RTF for rich apps)
    func copyToClipboard(_ text: String) {
        let pasteboard = UIPasteboard.general

        // Set plain text
        pasteboard.string = text

        // Also try to set RTF for rich text apps
        if let rtfData = text.data(using: .utf8) {
            pasteboard.setData(rtfData, forPasteboardType: "public.utf8-plain-text")
        }
    }

    // MARK: - Section Builders

    private func buildHeader(meeting: Meeting, managerName: String, style: ExportStyle) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        let formattedDate = dateFormatter.string(from: meeting.date)

        switch style {
        case .professional:
            return """
            \(meeting.meetingType) with \(managerName)
            \(formattedDate)
            \(dividerLine)
            """

        case .casual:
            return """
            📅 \(meeting.meetingType) with \(managerName)
            🕐 \(formattedDate)
            """

        case .minimal:
            let shortDate = DateFormatter.localizedString(from: meeting.date, dateStyle: .medium, timeStyle: .short)
            return "\(meeting.meetingType) with \(managerName) | \(shortDate)"
        }
    }

    private func buildSection(
        _ section: ExportSection,
        meeting: Meeting,
        style: ExportStyle,
        agendaItems: [AgendaItem],
        actionItems: [ActionItem],
        previousMeeting: Meeting?
    ) -> String? {

        switch section {
        case .header:
            return nil // Handled separately

        case .agenda:
            guard !agendaItems.isEmpty else { return nil }
            let items = agendaItems.sorted { $0.order < $1.order }.map { $0.title }
            return buildListSection(title: section, items: items, style: style)

        case .lastMeetingRecap:
            guard let prev = previousMeeting, !prev.notes.isEmpty else { return nil }
            return buildTextSection(title: section, content: prev.notes, style: style)

        case .goalsProgress:
            var items: [String] = []
            if !meeting.thisWeekGoals.isEmpty {
                items.append(contentsOf: meeting.thisWeekGoals.map { "Goal: \($0)" })
            }
            if !meeting.thisWeekProgress.isEmpty {
                items.append(contentsOf: meeting.thisWeekProgress.map { "Progress: \($0)" })
            }
            guard !items.isEmpty else { return nil }
            return buildListSection(title: section, items: items, style: style)

        case .wentWell:
            guard !meeting.wentWell.isEmpty else { return nil }
            return buildListSection(title: section, items: meeting.wentWell, style: style)

        case .didntGoWell:
            guard !meeting.didntGoWell.isEmpty else { return nil }
            return buildListSection(title: section, items: meeting.didntGoWell, style: style)

        case .blockers:
            guard !meeting.blockers.isEmpty else { return nil }
            return buildListSection(title: section, items: meeting.blockers, style: style)

        case .escalations:
            guard !meeting.escalations.isEmpty else { return nil }
            return buildListSection(title: section, items: meeting.escalations, style: style)

        case .actionItems:
            guard !actionItems.isEmpty else { return nil }
            let items = actionItems.map { item -> String in
                let owner = item.owner == .me ? "You" : "Them"
                let dueStr = item.dueDate.map { formatDueDate($0) } ?? ""
                return "[\(owner)] \(item.title)\(dueStr.isEmpty ? "" : " — \(dueStr)")"
            }
            return buildListSection(title: section, items: items, style: style, useCheckbox: true)

        case .nextSteps:
            guard !meeting.nextWeekGoals.isEmpty else { return nil }
            return buildListSection(title: section, items: meeting.nextWeekGoals, style: style)
        }
    }

    // MARK: - Formatting Helpers

    private func buildListSection(
        title: ExportSection,
        items: [String],
        style: ExportStyle,
        useCheckbox: Bool = false
    ) -> String {
        let icon = settings.iconForExportSection(title)
        let bullet = bulletForStyle(style, useCheckbox: useCheckbox)

        switch style {
        case .professional:
            let header = icon.isEmpty ? title.displayName.uppercased() : icon
            let itemsText = items.map { "\(bullet) \($0)" }.joined(separator: "\n")
            return """
            \(header)
            \(itemsText)
            """

        case .casual:
            let header = icon.isEmpty ? title.displayName : "\(icon) \(title.displayName)"
            let itemsText = items.map { "  \(bullet) \($0)" }.joined(separator: "\n")
            return """
            \(header)
            \(itemsText)
            """

        case .minimal:
            let itemsText = items.map { "\(bullet) \($0)" }.joined(separator: "\n")
            return """
            \(title.displayName)
            \(itemsText)
            """
        }
    }

    private func buildTextSection(title: ExportSection, content: String, style: ExportStyle) -> String {
        let icon = settings.iconForExportSection(title)

        switch style {
        case .professional:
            let header = icon.isEmpty ? title.displayName.uppercased() : icon
            return """
            \(header)
            \(content)
            """

        case .casual:
            let header = icon.isEmpty ? title.displayName : "\(icon) \(title.displayName)"
            return """
            \(header)
            \(content)
            """

        case .minimal:
            return """
            \(title.displayName)
            \(content)
            """
        }
    }

    private func bulletForStyle(_ style: ExportStyle, useCheckbox: Bool = false) -> String {
        if useCheckbox {
            switch style {
            case .professional: return "□"
            case .casual: return "→"
            case .minimal: return "-"
            }
        } else {
            switch style {
            case .professional: return "•"
            case .casual: return "▸"
            case .minimal: return "-"
            }
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Due \(formatter.string(from: date))"
    }
}
