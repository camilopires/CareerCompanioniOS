import Foundation

/// Represents a preview of AI-improved content before applying
struct NoteImprovementPreview: Identifiable {
    let id = UUID()
    let sectionType: MeetingSectionType
    let improvementType: NoteImprovementType
    let originalContent: [String]
    let improvedContent: [String]

    /// Single string version for notes section
    var originalText: String {
        originalContent.joined(separator: "\n")
    }

    var improvedText: String {
        improvedContent.joined(separator: "\n")
    }

    /// Check if there are actual changes
    var hasChanges: Bool {
        originalContent != improvedContent
    }
}

/// Result of Smart Notes categorization
struct SmartNotesResult: Identifiable {
    let id = UUID()
    let categorizedItems: [MeetingSectionType: [String]]
    let uncategorizedItems: [String]

    /// Check if there are any items that couldn't be categorized
    var hasUncategorized: Bool {
        !uncategorizedItems.isEmpty
    }

    /// Total number of items categorized
    var totalCategorized: Int {
        categorizedItems.values.reduce(0) { $0 + $1.count }
    }
}

/// Represents a batch improvement operation
struct BatchImprovementPreview: Identifiable {
    let id = UUID()
    let improvements: [NoteImprovementPreview]
    let improvementType: NoteImprovementType

    /// Total sections with changes
    var sectionsWithChanges: Int {
        improvements.filter { $0.hasChanges }.count
    }

    /// Check if any improvements were made
    var hasChanges: Bool {
        sectionsWithChanges > 0
    }
}
