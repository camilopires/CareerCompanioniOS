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

    // MARK: - Note Improvement (v2.9)

    /// Improve text based on the selected improvement type
    func improveText(
        _ text: String,
        type: NoteImprovementType,
        section: MeetingSectionType
    ) async -> String {
        guard isAvailable && isEnabled else { return text }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }

        isProcessing = true
        defer { isProcessing = false }

        switch type {
        case .professionalTone:
            return makeProfessional(text, section: section)
        case .expandDetails:
            return expandDetails(text, section: section)
        case .fixGrammar:
            return fixGrammar(text)
        case .simplify:
            return simplify(text)
        case .addContext:
            return addContext(text, section: section)
        }
    }

    /// Improve a list of items
    func improveItems(
        _ items: [String],
        type: NoteImprovementType,
        section: MeetingSectionType
    ) async -> [String] {
        guard isAvailable && isEnabled else { return items }
        guard !items.isEmpty else { return items }

        isProcessing = true
        defer { isProcessing = false }

        var improved: [String] = []
        for item in items {
            // Process without nested isProcessing toggle
            let improvedItem: String
            switch type {
            case .professionalTone:
                improvedItem = makeProfessional(item, section: section)
            case .expandDetails:
                improvedItem = expandDetails(item, section: section)
            case .fixGrammar:
                improvedItem = fixGrammar(item)
            case .simplify:
                improvedItem = simplify(item)
            case .addContext:
                improvedItem = addContext(item, section: section)
            }
            improved.append(improvedItem)
        }
        return improved
    }

    // MARK: - Improvement Helpers

    private func makeProfessional(_ text: String, section: MeetingSectionType) -> String {
        var result = text

        // Capitalize first letter
        if let first = result.first {
            result = String(first).uppercased() + result.dropFirst()
        }

        // Replace informal phrases
        let replacements: [(String, String)] = [
            ("gonna", "going to"),
            ("wanna", "want to"),
            ("kinda", "somewhat"),
            ("sorta", "sort of"),
            ("gotta", "have to"),
            ("really good", "excellent"),
            ("really bad", "challenging"),
            ("messed up", "encountered issues with"),
            ("screwed up", "made an error in"),
            ("super", "very"),
            ("awesome", "excellent"),
            ("cool", "good"),
            ("stuff", "items"),
            ("things", "aspects"),
            ("a lot", "significantly"),
            ("lots of", "numerous"),
            ("pretty much", "essentially"),
            ("kind of", "somewhat"),
            ("a bunch of", "several"),
            ("totally", "completely"),
            ("huge", "significant"),
            ("crazy", "unexpected"),
            ("insane", "remarkable")
        ]

        for (informal, formal) in replacements {
            result = result.replacingOccurrences(of: informal, with: formal, options: .caseInsensitive)
        }

        // Add period if missing
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !trimmed.hasSuffix(".") && !trimmed.hasSuffix("!") && !trimmed.hasSuffix("?") {
            result = trimmed + "."
        }

        return result
    }

    private func expandDetails(_ text: String, section: MeetingSectionType) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Only suggest expansion for short text
        guard trimmed.count < 80 else { return text }

        // Add context hints based on section type
        let hint: String
        switch section {
        case .wentWell:
            hint = " — consider adding: specific impact, metrics, or stakeholder feedback"
        case .didntGoWell:
            hint = " — consider adding: root cause analysis and lessons learned"
        case .blockers:
            hint = " — consider adding: timeline impact, dependencies, and mitigation steps"
        case .escalations:
            hint = " — consider adding: urgency level, decision needed, and deadline"
        case .thisWeekGoals:
            hint = " — consider adding: success criteria and key milestones"
        case .thisWeekProgress:
            hint = " — consider adding: percentage complete and remaining work"
        case .keyMetrics:
            hint = " — consider adding: target value, current value, and trend"
        case .nextWeekGoals:
            hint = " — consider adding: dependencies and potential blockers"
        case .notes:
            hint = " — consider adding: action items, decisions made, and follow-ups"
        }

        return trimmed + hint
    }

    private func fixGrammar(_ text: String) -> String {
        var result = text

        // Basic capitalization fixes
        if let first = result.first, first.isLowercase {
            result = String(first).uppercased() + result.dropFirst()
        }

        // Fix capitalization after periods
        var chars = Array(result)
        var shouldCapitalize = false
        for i in chars.indices {
            if chars[i] == "." || chars[i] == "!" || chars[i] == "?" {
                shouldCapitalize = true
            } else if shouldCapitalize && chars[i].isLetter {
                chars[i] = Character(chars[i].uppercased())
                shouldCapitalize = false
            } else if !chars[i].isWhitespace {
                shouldCapitalize = false
            }
        }
        result = String(chars)

        // Common typos and contractions
        let fixes: [(String, String)] = [
            ("i ", "I "),
            (" i ", " I "),
            ("i'm", "I'm"),
            ("i've", "I've"),
            ("i'll", "I'll"),
            ("i'd", "I'd"),
            ("dont", "don't"),
            ("cant", "can't"),
            ("wont", "won't"),
            ("didnt", "didn't"),
            ("couldnt", "couldn't"),
            ("wouldnt", "wouldn't"),
            ("shouldnt", "shouldn't"),
            ("wasnt", "wasn't"),
            ("werent", "weren't"),
            ("isnt", "isn't"),
            ("arent", "aren't"),
            ("hasnt", "hasn't"),
            ("havent", "haven't"),
            ("doesnt", "doesn't"),
            ("ive", "I've"),
            ("youre", "you're"),
            ("theyre", "they're"),
            ("weve", "we've"),
            ("thats", "that's"),
            ("whats", "what's"),
            ("  ", " ")
        ]

        for (typo, correction) in fixes {
            result = result.replacingOccurrences(of: typo, with: correction, options: .caseInsensitive)
        }

        // Remove multiple spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        // Add period if missing
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !trimmed.hasSuffix(".") && !trimmed.hasSuffix("!") && !trimmed.hasSuffix("?") {
            result = trimmed + "."
        }

        return result
    }

    private func simplify(_ text: String) -> String {
        var result = text

        // Remove filler words
        let fillerWords = [
            "basically", "actually", "literally", "honestly",
            "essentially", "obviously", "clearly", "simply",
            "just", "really", "very", "quite", "rather",
            "definitely", "certainly", "absolutely", "probably",
            "perhaps", "maybe", "seemingly", "apparently"
        ]

        for filler in fillerWords {
            // Remove filler word with surrounding spaces
            result = result.replacingOccurrences(of: " \(filler) ", with: " ", options: .caseInsensitive)
            // Remove at start of sentence
            if result.lowercased().hasPrefix("\(filler) ") {
                result = String(result.dropFirst(filler.count + 1))
            }
        }

        // Remove redundant phrases
        let redundancies: [(String, String)] = [
            ("in order to", "to"),
            ("due to the fact that", "because"),
            ("at this point in time", "now"),
            ("in the event that", "if"),
            ("for the purpose of", "to"),
            ("in the near future", "soon"),
            ("at the present time", "now"),
            ("in spite of the fact that", "although"),
            ("on a daily basis", "daily"),
            ("on a weekly basis", "weekly")
        ]

        for (redundant, simple) in redundancies {
            result = result.replacingOccurrences(of: redundant, with: simple, options: .caseInsensitive)
        }

        // Remove double spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addContext(_ text: String, section: MeetingSectionType) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add section-appropriate context prefix
        let prefix: String
        switch section {
        case .wentWell:
            prefix = "Successfully "
        case .didntGoWell:
            prefix = "Challenge: "
        case .blockers:
            prefix = "Blocked by: "
        case .escalations:
            prefix = "Needs escalation: "
        case .thisWeekGoals:
            prefix = "Goal: "
        case .thisWeekProgress:
            prefix = "Progress: "
        case .keyMetrics:
            prefix = "Metric: "
        case .nextWeekGoals:
            prefix = "Next week: "
        case .notes:
            return trimmed  // No prefix for notes
        }

        // Only add prefix if not already present or similar
        let lowerText = trimmed.lowercased()
        let lowerPrefix = prefix.lowercased().trimmingCharacters(in: .whitespaces).dropLast()

        if !lowerText.hasPrefix(String(lowerPrefix)) {
            // Lowercase the first character after the prefix
            if let first = trimmed.first, first.isUppercase {
                return prefix + String(first).lowercased() + trimmed.dropFirst()
            }
            return prefix + trimmed
        }

        return trimmed
    }

    // MARK: - Smart Notes Categorization (v2.9)

    /// Categorize rough notes into appropriate meeting sections
    func categorizeNotes(
        _ rawNotes: String,
        selectedSections: Set<MeetingSectionType>
    ) async -> SmartNotesResult {
        guard isAvailable && isEnabled else {
            return SmartNotesResult(categorizedItems: [:], uncategorizedItems: [rawNotes])
        }
        guard !rawNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SmartNotesResult(categorizedItems: [:], uncategorizedItems: [])
        }

        isProcessing = true
        defer { isProcessing = false }

        // Split into sentences/items
        let items = splitIntoItems(rawNotes)

        var categorized: [MeetingSectionType: [String]] = [:]
        var uncategorized: [String] = []

        for item in items {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if let category = categorizeItem(trimmed, availableSections: selectedSections) {
                categorized[category, default: []].append(trimmed)
            } else {
                uncategorized.append(trimmed)
            }
        }

        return SmartNotesResult(categorizedItems: categorized, uncategorizedItems: uncategorized)
    }

    private func splitIntoItems(_ text: String) -> [String] {
        var items: [String] = []

        // Split by newlines first
        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            var cleaned = line
            // Remove bullet points
            cleaned = cleaned.replacingOccurrences(of: "^[\\-\\*\\•\\◦\\▸\\→]\\s*", with: "", options: .regularExpression)
            // Remove numbered list markers
            cleaned = cleaned.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            // Remove checkbox markers
            cleaned = cleaned.replacingOccurrences(of: "^\\[[ x]\\]\\s*", with: "", options: .regularExpression)

            let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append(trimmed)
            }
        }

        return items
    }

    private func categorizeItem(_ text: String, availableSections: Set<MeetingSectionType>) -> MeetingSectionType? {
        let lowerText = text.lowercased()

        // Use NLP to analyze the text
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        // Analyze sentiment
        var sentimentScore: Double = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let score = tag?.rawValue, let value = Double(score) {
                sentimentScore = value
            }
            return true
        }

        // Keyword-based categorization
        let wentWellKeywords = ["achieved", "completed", "success", "won", "improved", "great", "excellent",
                                "good progress", "milestone", "accomplished", "delivered", "shipped",
                                "fixed", "resolved", "positive", "proud", "celebrated"]

        let didntGoWellKeywords = ["failed", "missed", "delayed", "struggled", "issue", "problem",
                                   "didn't work", "challenge", "difficult", "frustrated", "concern",
                                   "setback", "mistake", "error", "wrong", "bad"]

        let blockerKeywords = ["blocked", "waiting", "depends on", "need", "can't proceed", "stuck",
                               "blocker", "blocking", "dependency", "waiting for", "pending",
                               "on hold", "paused", "requires", "needs approval"]

        let escalationKeywords = ["escalate", "manager", "leadership", "decision needed", "approval",
                                  "urgent", "priority", "critical", "executive", "senior",
                                  "higher level", "attention needed", "risk"]

        let goalKeywords = ["goal", "objective", "aim", "target", "plan to", "will", "want to",
                           "intend to", "looking to", "hoping to", "going to"]

        let progressKeywords = ["progress", "completed", "done", "finished", "working on",
                               "started", "continuing", "in progress", "underway", "ongoing",
                               "moving forward", "advancing"]

        let metricKeywords = ["metric", "kpi", "percentage", "number", "%", "count", "rate",
                             "velocity", "score", "increase", "decrease", "ratio", "average"]

        let nextWeekKeywords = ["next week", "next sprint", "upcoming", "future", "later",
                               "following week", "next period", "carry over"]

        // Check each category (only if section is selected)
        // Order matters - check more specific patterns first

        if availableSections.contains(.blockers) && blockerKeywords.contains(where: { lowerText.contains($0) }) {
            return .blockers
        }

        if availableSections.contains(.escalations) && escalationKeywords.contains(where: { lowerText.contains($0) }) {
            return .escalations
        }

        if availableSections.contains(.keyMetrics) && metricKeywords.contains(where: { lowerText.contains($0) }) {
            return .keyMetrics
        }

        if availableSections.contains(.nextWeekGoals) && nextWeekKeywords.contains(where: { lowerText.contains($0) }) {
            return .nextWeekGoals
        }

        if availableSections.contains(.thisWeekProgress) && progressKeywords.contains(where: { lowerText.contains($0) }) {
            return .thisWeekProgress
        }

        if availableSections.contains(.thisWeekGoals) && goalKeywords.contains(where: { lowerText.contains($0) }) {
            return .thisWeekGoals
        }

        // Use sentiment for went well / didn't go well if keywords don't match
        if availableSections.contains(.wentWell) && (sentimentScore > 0.3 || wentWellKeywords.contains(where: { lowerText.contains($0) })) {
            return .wentWell
        }

        if availableSections.contains(.didntGoWell) && (sentimentScore < -0.3 || didntGoWellKeywords.contains(where: { lowerText.contains($0) })) {
            return .didntGoWell
        }

        return nil
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
