import Foundation
import SwiftData

/// Represents an action item from a 1:1 meeting or standalone task
@Model
final class SDActionItem {
    @Attribute(.unique) var id: UUID
    var meeting: SDMeeting?
    var title: String
    var itemDescription: String
    var dueDate: Date?
    var priorityRaw: String
    var statusRaw: String
    var ownerRaw: String
    var links: [String]
    var createdAt: Date
    var completedAt: Date?
    var completionNotes: String?

    // MARK: - Enum Computed Properties

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var status: ActionItemStatus {
        get { ActionItemStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var owner: Owner {
        get { Owner(rawValue: ownerRaw) ?? .me }
        set { ownerRaw = newValue.rawValue }
    }

    // MARK: - URL Computed Properties

    var linkURLs: [URL] {
        get { links.compactMap { URL(string: $0) } }
        set { links = newValue.map { $0.absoluteString } }
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let dueDate, status != .completed else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueThisWeek: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var formattedDueDate: String? {
        guard let dueDate else { return nil }

        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else {
            return dueDate.formatted(date: .abbreviated, time: .omitted)
        }
    }

    var isOpen: Bool {
        status != .completed
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        meeting: SDMeeting? = nil,
        title: String,
        itemDescription: String = "",
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: ActionItemStatus = .open,
        owner: Owner = .me,
        links: [URL] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        completionNotes: String? = nil
    ) {
        self.id = id
        self.meeting = meeting
        self.title = title
        self.itemDescription = itemDescription
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.statusRaw = status.rawValue
        self.ownerRaw = owner.rawValue
        self.links = links.map { $0.absoluteString }
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.completionNotes = completionNotes
    }

    // MARK: - Mutations

    func markComplete(notes: String? = nil) {
        status = .completed
        completedAt = Date()
        completionNotes = notes
    }

    func reopen() {
        status = .open
        completedAt = nil
        completionNotes = nil
    }

    /// Convert to ActionItem struct for view compatibility
    func toActionItem() -> ActionItem {
        ActionItem(
            id: id,
            meetingID: meeting?.id,
            title: title,
            itemDescription: itemDescription,
            dueDate: dueDate,
            priority: priority,
            status: status,
            owner: owner,
            links: linkURLs,
            createdAt: createdAt,
            completedAt: completedAt,
            completionNotes: completionNotes
        )
    }

    /// Update from ActionItem struct
    func update(from item: ActionItem) {
        title = item.title
        itemDescription = item.itemDescription
        dueDate = item.dueDate
        priority = item.priority
        status = item.status
        owner = item.owner
        linkURLs = item.links
        completedAt = item.completedAt
        completionNotes = item.completionNotes
    }
}
