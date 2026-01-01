import Foundation

/// Provides in-memory demo data for exploring the app
/// Data is NEVER saved to CloudKit - it exists only in memory
struct DemoDataProvider {

    // MARK: - Static Manager IDs (for consistent relationships)

    private static let manager1ID = UUID()
    private static let manager2ID = UUID()

    // MARK: - Demo Data

    /// Sample managers for demo mode
    static var managers: [Manager] {
        [
            Manager(
                id: manager1ID,
                name: "Sarah Johnson",
                email: "sarah.johnson@company.com",
                relationship: .myManager
            ),
            Manager(
                id: manager2ID,
                name: "Michael Chen",
                email: "michael.chen@company.com",
                relationship: .myManager
            )
        ]
    }

    /// Sample meetings for demo mode (with multiple managers)
    static var meetings: [Meeting] {
        let now = Date()
        let calendar = Calendar.current

        return [
            // Sarah Johnson's meetings
            // Upcoming meeting - next week
            Meeting(
                managerID: manager1ID,
                date: calendar.date(byAdding: .day, value: 7, to: now)!,
                status: .scheduled
            ),
            // Completed meeting - last week
            Meeting(
                managerID: manager1ID,
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                status: .completed,
                notes: "Great discussion about Q4 priorities and team structure.",
                wentWell: [
                    "Completed the API migration ahead of schedule",
                    "Got positive feedback from stakeholders on the demo"
                ],
                didntGoWell: [
                    "Missed the documentation deadline"
                ],
                blockers: [
                    "Waiting for design assets from the design team"
                ],
                escalations: [
                    "Need additional budget for cloud infrastructure"
                ],
                weekSentiment: 4,
                meetingSentiment: 5
            ),
            // Completed meeting - two weeks ago
            Meeting(
                managerID: manager1ID,
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                status: .completed,
                notes: "Sprint retrospective and planning for the next quarter.",
                wentWell: [
                    "Sprint velocity improved by 20%"
                ],
                didntGoWell: [
                    "Some technical debt accumulated"
                ],
                weekSentiment: 3,
                meetingSentiment: 4
            ),

            // Michael Chen's meetings
            // Upcoming meeting - in 3 days
            Meeting(
                managerID: manager2ID,
                date: calendar.date(byAdding: .day, value: 3, to: now)!,
                status: .scheduled
            ),
            // Completed meeting - 5 days ago
            Meeting(
                managerID: manager2ID,
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                status: .completed,
                notes: "Discussed career growth and upcoming project assignments.",
                wentWell: [
                    "Got assigned to lead the new mobile initiative",
                    "Positive feedback on mentoring efforts"
                ],
                didntGoWell: [
                    "Need to improve time estimation skills"
                ],
                weekSentiment: 5,
                meetingSentiment: 4
            )
        ]
    }

    /// Sample action items for demo mode
    static var actionItems: [ActionItem] {
        let now = Date()
        let calendar = Calendar.current
        let meeting = meetings.first

        return [
            ActionItem(
                meetingID: meeting?.id,
                title: "Review Q4 objectives",
                itemDescription: "Review and finalize the Q4 objectives document",
                dueDate: calendar.date(byAdding: .day, value: 3, to: now),
                priority: .high
            ),
            ActionItem(
                meetingID: meeting?.id,
                title: "Schedule team retrospective",
                dueDate: calendar.date(byAdding: .day, value: 7, to: now),
                priority: .medium
            ),
            ActionItem(
                title: "Update API documentation",
                itemDescription: "Update the API documentation with new endpoints",
                dueDate: calendar.date(byAdding: .day, value: -1, to: now), // Overdue
                priority: .low
            ),
            ActionItem(
                title: "Follow up on budget request",
                priority: .high,
                owner: .manager
            ),
            ActionItem(
                title: "Prepare presentation for all-hands",
                dueDate: calendar.date(byAdding: .day, value: 14, to: now),
                priority: .medium,
                status: .inProgress
            )
        ]
    }

    /// Sample career goals for demo mode
    static var careerGoals: [CareerGoal] {
        let now = Date()
        let calendar = Calendar.current

        return [
            CareerGoal(
                title: "Become a Senior Engineer",
                goalDescription: "Develop the skills and demonstrate the impact needed to be promoted to Senior Engineer",
                category: .technical,
                targetDate: calendar.date(byAdding: .month, value: 6, to: now),
                status: .inProgress,
                priority: .primary,
                successMetrics: "Lead 2 major projects, mentor 1 junior developer, improve system reliability by 20%",
                trackingMethod: "Monthly review with manager, quarterly self-assessment",
                progress: 45,
                skills: ["System Design", "Mentoring", "Technical Leadership"]
            ),
            CareerGoal(
                title: "Improve Public Speaking",
                goalDescription: "Become more confident presenting to large groups",
                category: .communication,
                targetDate: calendar.date(byAdding: .month, value: 3, to: now),
                status: .inProgress,
                priority: .secondary,
                progress: 30,
                skills: ["Presentation", "Communication"]
            ),
            CareerGoal(
                title: "Learn Cloud Architecture",
                goalDescription: "Gain expertise in AWS/GCP cloud architecture patterns",
                category: .domainKnowledge,
                status: .notStarted,
                priority: .secondary,
                progress: 0,
                skills: ["AWS", "Cloud Architecture", "Infrastructure"]
            )
        ]
    }

    /// Sample achievements for demo mode
    static var achievements: [Achievement] {
        let now = Date()
        let calendar = Calendar.current

        return [
            Achievement(
                title: "Led API Migration Project",
                achievementDescription: "Successfully led the migration of our legacy API to a new microservices architecture",
                dateAchieved: calendar.date(byAdding: .day, value: -30, to: now)!,
                impactStatement: "Reduced API response times by 40% and improved system reliability to 99.9% uptime",
                tags: ["Technical Leadership", "Architecture", "Performance"],
                visibility: .manager
            ),
            Achievement(
                title: "Mentored Junior Developer",
                achievementDescription: "Guided a junior developer through their first major feature implementation",
                dateAchieved: calendar.date(byAdding: .day, value: -14, to: now)!,
                impactStatement: "Junior developer successfully delivered feature on time and received positive feedback",
                tags: ["Mentoring", "Leadership"],
                visibility: .manager
            ),
            Achievement(
                title: "Presented at Team Tech Talk",
                achievementDescription: "Gave a 30-minute presentation on modern Swift concurrency patterns",
                dateAchieved: calendar.date(byAdding: .day, value: -7, to: now)!,
                impactStatement: "Team adopted async/await patterns, reducing callback complexity across 5 services",
                tags: ["Public Speaking", "Knowledge Sharing"],
                visibility: .publicVisible
            )
        ]
    }
}
