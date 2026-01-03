import Foundation
import SwiftData

/// Represents a 1:1 meeting with a manager, report, mentor, peer, or other person
@Model
final class SDMeeting {
    @Attribute(.unique) var id: UUID
    var manager: SDManager?
    var date: Date
    var statusRaw: String
    var perspectiveRaw: String
    var meetingType: String
    var notes: String
    var wentWell: [String]
    var didntGoWell: [String]
    var blockers: [String]
    var escalations: [String]
    var thisWeekGoals: [String]
    var thisWeekProgress: [String]
    var keyMetrics: [String]
    var nextWeekGoals: [String]
    var weekSentiment: Int?
    var meetingSentiment: Int?
    var calendarEventID: String?
    var recurrenceData: Data?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SDAgendaItem.meeting)
    var agendaItems: [SDAgendaItem] = []

    @Relationship(deleteRule: .nullify, inverse: \SDActionItem.meeting)
    var actionItems: [SDActionItem] = []

    // MARK: - Enum Computed Properties

    var status: MeetingStatus {
        get { MeetingStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    var perspective: MeetingPerspective {
        get { MeetingPerspective(rawValue: perspectiveRaw) ?? .asEmployee }
        set { perspectiveRaw = newValue.rawValue }
    }

    var recurrence: RecurrenceRule? {
        get {
            guard let data = recurrenceData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            recurrenceData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Computed Properties

    var isUpcoming: Bool {
        status == .scheduled && date > Date()
    }

    var isPast: Bool {
        status == .completed || date < Date()
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    var weekSentimentValue: Sentiment? {
        weekSentiment.flatMap { Sentiment(rawValue: $0) }
    }

    var meetingSentimentValue: Sentiment? {
        meetingSentiment.flatMap { Sentiment(rawValue: $0) }
    }

    var isSyncedToCalendar: Bool {
        calendarEventID != nil
    }

    var isRecurring: Bool {
        recurrence != nil
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        manager: SDManager? = nil,
        date: Date,
        status: MeetingStatus = .scheduled,
        perspective: MeetingPerspective = .asEmployee,
        meetingType: String = "1:1",
        notes: String = "",
        wentWell: [String] = [],
        didntGoWell: [String] = [],
        blockers: [String] = [],
        escalations: [String] = [],
        thisWeekGoals: [String] = [],
        thisWeekProgress: [String] = [],
        keyMetrics: [String] = [],
        nextWeekGoals: [String] = [],
        weekSentiment: Int? = nil,
        meetingSentiment: Int? = nil,
        calendarEventID: String? = nil,
        recurrence: RecurrenceRule? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.manager = manager
        self.date = date
        self.statusRaw = status.rawValue
        self.perspectiveRaw = perspective.rawValue
        self.meetingType = meetingType
        self.notes = notes
        self.wentWell = wentWell
        self.didntGoWell = didntGoWell
        self.blockers = blockers
        self.escalations = escalations
        self.thisWeekGoals = thisWeekGoals
        self.thisWeekProgress = thisWeekProgress
        self.keyMetrics = keyMetrics
        self.nextWeekGoals = nextWeekGoals
        self.weekSentiment = weekSentiment
        self.meetingSentiment = meetingSentiment
        self.calendarEventID = calendarEventID
        self.recurrenceData = try? JSONEncoder().encode(recurrence)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convert to Meeting struct for view compatibility
    func toMeeting() -> Meeting {
        Meeting(
            id: id,
            managerID: manager?.id ?? UUID(),
            date: date,
            status: status,
            perspective: perspective,
            meetingType: meetingType,
            notes: notes,
            wentWell: wentWell,
            didntGoWell: didntGoWell,
            blockers: blockers,
            escalations: escalations,
            thisWeekGoals: thisWeekGoals,
            thisWeekProgress: thisWeekProgress,
            keyMetrics: keyMetrics,
            nextWeekGoals: nextWeekGoals,
            weekSentiment: weekSentiment,
            meetingSentiment: meetingSentiment,
            calendarEventID: calendarEventID,
            recurrence: recurrence,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Update SDMeeting from Meeting struct
    func update(from meeting: Meeting) {
        date = meeting.date
        statusRaw = meeting.status.rawValue
        perspectiveRaw = meeting.perspective.rawValue
        meetingType = meeting.meetingType
        notes = meeting.notes
        wentWell = meeting.wentWell
        didntGoWell = meeting.didntGoWell
        blockers = meeting.blockers
        escalations = meeting.escalations
        thisWeekGoals = meeting.thisWeekGoals
        thisWeekProgress = meeting.thisWeekProgress
        keyMetrics = meeting.keyMetrics
        nextWeekGoals = meeting.nextWeekGoals
        weekSentiment = meeting.weekSentiment
        meetingSentiment = meeting.meetingSentiment
        calendarEventID = meeting.calendarEventID
        recurrence = meeting.recurrence
        updatedAt = meeting.updatedAt
    }
}
