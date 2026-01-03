import Foundation

/// Defines how a meeting repeats
/// Supports daily, weekly (with optional specific weekday), and monthly patterns
struct RecurrenceRule: Codable, Equatable, Hashable {

    // MARK: - Nested Types

    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case daily = "day"
        case weekly = "week"
        case monthly = "month"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .daily: return "Day"
            case .weekly: return "Week"
            case .monthly: return "Month"
            }
        }

        var pluralName: String {
            switch self {
            case .daily: return "Days"
            case .weekly: return "Weeks"
            case .monthly: return "Months"
            }
        }
    }

    enum Weekday: Int, Codable, CaseIterable, Identifiable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        var id: Int { rawValue }

        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }

        var fullName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }

    // MARK: - Properties

    /// How often the meeting repeats (daily, weekly, monthly)
    var frequency: Frequency

    /// Repeat every X frequency units (e.g., every 2 weeks)
    var interval: Int

    /// For weekly frequency: specific day of week (nil = same day as original meeting)
    var weekday: Weekday?

    // MARK: - Initialization

    init(frequency: Frequency = .weekly, interval: Int = 1, weekday: Weekday? = nil) {
        self.frequency = frequency
        self.interval = max(1, interval) // Minimum interval is 1
        self.weekday = weekday
    }

    // MARK: - Presets

    /// Weekly recurrence (every week on same day)
    static let weekly = RecurrenceRule(frequency: .weekly, interval: 1)

    /// Biweekly recurrence (every 2 weeks on same day)
    static let biweekly = RecurrenceRule(frequency: .weekly, interval: 2)

    /// Monthly recurrence (every month on same date)
    static let monthly = RecurrenceRule(frequency: .monthly, interval: 1)

    // MARK: - Display

    /// Human-readable description of the recurrence
    var displayText: String {
        switch frequency {
        case .daily:
            if interval == 1 {
                return "Daily"
            } else {
                return "Every \(interval) days"
            }

        case .weekly:
            if interval == 1 {
                if let day = weekday {
                    return "Every \(day.fullName)"
                }
                return "Weekly"
            } else {
                if let day = weekday {
                    return "Every \(interval) weeks on \(day.shortName)"
                }
                return "Every \(interval) weeks"
            }

        case .monthly:
            if interval == 1 {
                return "Monthly"
            } else {
                return "Every \(interval) months"
            }
        }
    }

    /// Short description for badges
    var shortText: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval)d"
        case .weekly:
            if interval == 1 {
                return weekday?.shortName ?? "Weekly"
            }
            return "Every \(interval)w"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval)mo"
        }
    }

    /// Icon for the recurrence
    var icon: String {
        "repeat"
    }

    // MARK: - Date Calculation

    /// Calculate the next occurrence date from a given date
    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date

        case .weekly:
            var nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: date) ?? date

            // If specific weekday is set, adjust to that day
            if let targetWeekday = weekday {
                // Get the weekday of nextDate
                let nextDateWeekday = calendar.component(.weekday, from: nextDate)

                if nextDateWeekday != targetWeekday.rawValue {
                    // Find the target weekday in the same week
                    let daysToAdd = (targetWeekday.rawValue - nextDateWeekday + 7) % 7
                    if daysToAdd == 0 {
                        // Same weekday, keep it
                    } else {
                        nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: nextDate) ?? nextDate
                    }
                }
            }

            return nextDate

        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        }
    }
}

// MARK: - Recurrence Preset

/// Quick preset options for the recurrence picker
enum RecurrencePreset: String, CaseIterable, Identifiable {
    case none = "Does not repeat"
    case weekly = "Weekly"
    case biweekly = "Every 2 weeks"
    case monthly = "Monthly"
    case custom = "Custom..."

    var id: String { rawValue }

    /// Convert preset to RecurrenceRule (nil for none, nil for custom - handled separately)
    var rule: RecurrenceRule? {
        switch self {
        case .none: return nil
        case .weekly: return .weekly
        case .biweekly: return .biweekly
        case .monthly: return .monthly
        case .custom: return nil // Custom is handled by the custom picker
        }
    }

    /// Create preset from a rule (returns .custom if not a standard preset)
    static func from(rule: RecurrenceRule?) -> RecurrencePreset {
        guard let rule = rule else { return .none }

        if rule == .weekly { return .weekly }
        if rule == .biweekly { return .biweekly }
        if rule == .monthly { return .monthly }

        return .custom
    }
}
