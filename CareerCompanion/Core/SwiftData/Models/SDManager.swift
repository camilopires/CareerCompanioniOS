import Foundation
import SwiftData

/// Represents a person the user has 1:1 meetings with (manager, report, mentor, peer, etc.)
@Model
final class SDManager {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String?
    var relationshipType: String
    var tags: [String]
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \SDMeeting.manager)
    var meetings: [SDMeeting] = []

    // MARK: - Computed Properties

    var isMyManager: Bool { relationshipType == "My Manager" }
    var isDirectReport: Bool { relationshipType == "Direct Report" }
    var isOtherRelationship: Bool { !isMyManager && !isDirectReport }

    var roleTitle: String {
        if isMyManager { return "Manager" }
        if isDirectReport { return "Report" }
        return relationshipType
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        relationshipType: String = "My Manager",
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.relationshipType = relationshipType
        self.tags = tags
        self.createdAt = createdAt
    }

    /// Create SDManager from Manager struct
    convenience init(from manager: Manager) {
        self.init(
            id: manager.id,
            name: manager.name,
            email: manager.email,
            relationshipType: manager.relationshipType,
            tags: manager.tags,
            createdAt: manager.createdAt
        )
    }

    /// Convert to Manager struct for view compatibility
    func toManager() -> Manager {
        Manager(
            id: id,
            name: name,
            email: email,
            relationshipType: relationshipType,
            tags: tags,
            createdAt: createdAt
        )
    }
}
