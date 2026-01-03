import Foundation
import SwiftData

/// Represents an item on the meeting agenda
@Model
final class SDAgendaItem {
    @Attribute(.unique) var id: UUID
    var meeting: SDMeeting?
    var title: String
    var notes: String
    var isCompleted: Bool
    var order: Int
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        meeting: SDMeeting? = nil,
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.meeting = meeting
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.order = order
        self.createdAt = createdAt
    }

    /// Convert to AgendaItem struct for view compatibility
    func toAgendaItem() -> AgendaItem {
        AgendaItem(
            id: id,
            meetingID: meeting?.id ?? UUID(),
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            order: order,
            createdAt: createdAt
        )
    }

    /// Update from AgendaItem struct
    func update(from item: AgendaItem) {
        title = item.title
        notes = item.notes
        isCompleted = item.isCompleted
        order = item.order
    }
}
