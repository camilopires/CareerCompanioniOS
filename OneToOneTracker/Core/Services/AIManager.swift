import Foundation
import NaturalLanguage

/// Manages AI-powered suggestions using Apple's on-device intelligence
/// Requires iOS 18+ for full Apple Intelligence features
@MainActor
final class AIManager: ObservableObject {
    static let shared = AIManager()

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var error: Error?

    // MARK: - Feature Availability

    /// Check if AI features are available (iOS 18+ and device supports Apple Intelligence)
    var isAvailable: Bool {
        if #available(iOS 18.0, *) {
            // Apple Intelligence is available on iOS 18+ on supported devices
            // This is a simplified check - full check would involve device capabilities
            return true
        }
        return false
    }

    /// Check if AI features are enabled by user
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "aiSuggestionsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "aiSuggestionsEnabled") }
    }

    private init() {
        // Default to enabled if available
        if !UserDefaults.standard.bool(forKey: "aiSuggestionsInitialized") {
            UserDefaults.standard.set(true, forKey: "aiSuggestionsEnabled")
            UserDefaults.standard.set(true, forKey: "aiSuggestionsInitialized")
        }
    }

    // MARK: - Agenda Suggestions

    /// Suggest agenda items based on previous meetings and open action items
    func suggestAgendaItems(
        previousMeetings: [Meeting],
        openActionItems: [ActionItem],
        managerName: String
    ) async -> [String] {
        guard isAvailable && isEnabled else { return [] }

        isProcessing = true
        defer { isProcessing = false }

        var suggestions: [String] = []

        // Analyze patterns from previous meetings
        let recurringTopics = analyzeRecurringTopics(from: previousMeetings)

        // Add suggestions based on patterns
        if !recurringTopics.isEmpty {
            suggestions.append(contentsOf: recurringTopics.prefix(2).map { "Follow up on: \($0)" })
        }

        // Suggest based on open action items
        let highPriorityItems = openActionItems.filter { $0.priority == .high && $0.status != .completed }
        if !highPriorityItems.isEmpty {
            suggestions.append("Review high-priority action items (\(highPriorityItems.count) open)")
        }

        // Suggest based on overdue items
        let overdueItems = openActionItems.filter { $0.isOverdue && $0.status != .completed }
        if !overdueItems.isEmpty {
            suggestions.append("Address overdue items (\(overdueItems.count) overdue)")
        }

        // Time-based suggestions
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())

        // Quarter-end suggestions
        if [3, 6, 9, 12].contains(month) {
            suggestions.append("Quarterly review and goal check-in")
        }

        // Year-end suggestions
        if month == 12 {
            suggestions.append("Year-end reflection and planning")
        }

        // Mid-year suggestions
        if month == 6 {
            suggestions.append("Mid-year career goals review")
        }

        // Standard suggestions based on meeting history
        if previousMeetings.isEmpty {
            suggestions.append(contentsOf: [
                "Introductions and working style preferences",
                "Current projects and priorities",
                "Career goals and development interests"
            ])
        } else if previousMeetings.count < 5 {
            suggestions.append("Discuss communication preferences")
        }

        // Add general suggestions if we have few
        if suggestions.count < 3 {
            suggestions.append(contentsOf: [
                "Updates since last meeting",
                "Current blockers or challenges",
                "Upcoming priorities"
            ].prefix(3 - suggestions.count))
        }

        return Array(Set(suggestions)).sorted()
    }

    /// Analyze topics that appear frequently across meetings
    private func analyzeRecurringTopics(from meetings: [Meeting]) -> [String] {
        var topicCounts: [String: Int] = [:]

        for meeting in meetings {
            // Analyze notes and went well items for keywords
            let allText = meeting.notes + " " + meeting.wentWell.joined(separator: " ") +
                         " " + meeting.didntGoWell.joined(separator: " ")

            // Simple keyword extraction using NLP
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = allText.lowercased()

            tagger.enumerateTags(in: allText.startIndex..<allText.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
                if tag == .noun {
                    let word = String(allText[tokenRange])
                    if word.count > 3 { // Filter short words
                        topicCounts[word, default: 0] += 1
                    }
                }
                return true
            }
        }

        // Return topics that appear in multiple meetings
        return topicCounts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key.capitalized }
    }

    // MARK: - Achievement Description Enhancement

    /// Improve an achievement description to be more impactful
    func improveAchievementDescription(
        original: String,
        context: String? = nil
    ) async -> String {
        guard isAvailable && isEnabled else { return original }
        guard !original.isEmpty else { return original }

        isProcessing = true
        defer { isProcessing = false }

        // For iOS 18+, we would use Apple Intelligence here
        // For now, provide structured improvements

        var improved = original

        // Ensure it starts with an action verb if it doesn't
        let actionVerbs = ["Led", "Developed", "Implemented", "Achieved", "Delivered", "Created", "Improved", "Designed", "Launched", "Built"]
        let startsWithVerb = actionVerbs.contains { original.lowercased().hasPrefix($0.lowercased()) }

        if !startsWithVerb {
            // Try to restructure to lead with action
            improved = "Successfully \(original.prefix(1).lowercased())\(original.dropFirst())"
        }

        // Add quantification hints if metrics seem missing
        let hasNumbers = original.rangeOfCharacter(from: .decimalDigits) != nil
        let hasPercentage = original.contains("%")

        if !hasNumbers && !hasPercentage {
            improved += " [Consider adding specific metrics or percentages to quantify impact]"
        }

        return improved
    }

    /// Suggest impact statement for an achievement
    func suggestImpactStatement(
        achievementTitle: String,
        achievementDescription: String
    ) async -> String {
        guard isAvailable && isEnabled else { return "" }

        isProcessing = true
        defer { isProcessing = false }

        // Templates based on common achievement types
        let keywords = (achievementTitle + " " + achievementDescription).lowercased()

        if keywords.contains("project") || keywords.contains("launch") || keywords.contains("deliver") {
            return "This project contributed to [team/business goal] by [specific outcome], resulting in [measurable benefit]."
        }

        if keywords.contains("mentor") || keywords.contains("train") || keywords.contains("coach") {
            return "This mentorship enabled [person/team] to [achieve specific outcome], improving [relevant metric] by [percentage]."
        }

        if keywords.contains("improve") || keywords.contains("optimize") || keywords.contains("enhance") {
            return "These improvements led to [X]% reduction in [metric] and [X]% increase in [outcome]."
        }

        if keywords.contains("present") || keywords.contains("speak") || keywords.contains("demo") {
            return "This presentation influenced [audience size] stakeholders, leading to [decision/adoption/change]."
        }

        return "This achievement directly contributed to [team/organization goal] by [specific measurable outcome]."
    }

    // MARK: - Action Item Title Suggestions

    /// Suggest clearer action item titles
    func suggestActionItemTitle(from text: String) async -> [String] {
        guard isAvailable && isEnabled else { return [] }
        guard !text.isEmpty else { return [] }

        isProcessing = true
        defer { isProcessing = false }

        var suggestions: [String] = []

        // Clean and structure the text
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's already short and clear, just return variations
        if cleanText.count < 50 {
            suggestions.append(cleanText)
        }

        // Create verb-first versions
        let actionVerbs = ["Complete", "Review", "Update", "Schedule", "Send", "Follow up on", "Prepare", "Create", "Research"]

        for verb in actionVerbs.prefix(3) {
            if !cleanText.lowercased().hasPrefix(verb.lowercased()) {
                let suggestion = "\(verb) \(cleanText.prefix(1).lowercased())\(cleanText.dropFirst())"
                if suggestion.count <= 100 {
                    suggestions.append(suggestion)
                }
            }
        }

        // Truncate if too long
        if cleanText.count > 80 {
            let truncated = String(cleanText.prefix(77)) + "..."
            suggestions.append(truncated)
        }

        return Array(Set(suggestions)).prefix(3).map { String($0) }
    }

    // MARK: - Meeting Summary

    /// Generate a summary of a meeting
    func summarizeMeeting(_ meeting: Meeting) async -> String {
        guard isAvailable && isEnabled else { return "" }

        isProcessing = true
        defer { isProcessing = false }

        var summaryParts: [String] = []

        // Key outcomes
        if !meeting.wentWell.isEmpty {
            summaryParts.append("Positive outcomes: \(meeting.wentWell.joined(separator: "; "))")
        }

        // Challenges discussed
        if !meeting.didntGoWell.isEmpty {
            summaryParts.append("Challenges: \(meeting.didntGoWell.joined(separator: "; "))")
        }

        // Blockers raised
        if !meeting.blockers.isEmpty {
            summaryParts.append("Blockers: \(meeting.blockers.joined(separator: "; "))")
        }

        // Items for escalation
        if !meeting.escalations.isEmpty {
            summaryParts.append("Escalations: \(meeting.escalations.joined(separator: "; "))")
        }

        // Sentiment summary
        if let weekSentiment = meeting.weekSentimentValue {
            summaryParts.append("Week sentiment: \(weekSentiment.displayName)")
        }

        if let meetingSentiment = meeting.meetingSentimentValue {
            summaryParts.append("Meeting sentiment: \(meetingSentiment.displayName)")
        }

        if summaryParts.isEmpty {
            return "No detailed notes recorded for this meeting."
        }

        return summaryParts.joined(separator: "\n\n")
    }
}

// MARK: - AI Error

enum AIError: LocalizedError {
    case notAvailable
    case notEnabled
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "AI features require iOS 18 or later."
        case .notEnabled:
            return "AI suggestions are disabled. Enable them in Settings."
        case .processingFailed:
            return "Failed to process AI suggestion."
        }
    }
}
