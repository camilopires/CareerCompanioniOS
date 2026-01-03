import Foundation
import SwiftUI
import SwiftData

/// ViewModel for career home screen
@MainActor
final class CareerHomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var goals: [CareerGoal] = []
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }
    private var sdGoals: [UUID: SDCareerGoal] = [:]
    private var sdAchievements: [UUID: SDAchievement] = [:]

    // MARK: - Computed Properties

    var activeGoals: [CareerGoal] {
        goals.filter { $0.isActive }
    }

    var activeGoalsCount: Int {
        activeGoals.count
    }

    var achievedGoalsCount: Int {
        goals.filter { $0.isAchieved }.count
    }

    var achievementsThisYear: Int {
        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date()))!
        return achievements.filter { $0.dateAchieved >= startOfYear }.count
    }

    var overallProgress: Double {
        guard !goals.isEmpty else { return 0 }
        let total = goals.reduce(0) { $0 + $1.progress }
        return Double(total) / Double(goals.count * 100)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            goals = DemoDataProvider.careerGoals
            achievements = DemoDataProvider.achievements
            isLoading = false
            return
        }

        do {
            let fetchedGoals = try DataManager.shared.fetchCareerGoals()
            goals = fetchedGoals.map { $0.toCareerGoal() }
            sdGoals = Dictionary(uniqueKeysWithValues: fetchedGoals.map { ($0.id, $0) })

            let fetchedAchievements = try DataManager.shared.fetchAchievements()
            achievements = fetchedAchievements.map { $0.toAchievement() }
            sdAchievements = Dictionary(uniqueKeysWithValues: fetchedAchievements.map { ($0.id, $0) })
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Actions

    func addGoal(_ goal: CareerGoal) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            goals.insert(goal, at: 0)
            Theme.successHaptic()
            return
        }

        do {
            let sdGoal = SDCareerGoal(
                id: goal.id,
                title: goal.title,
                goalDescription: goal.goalDescription,
                category: goal.category,
                targetDate: goal.targetDate,
                status: goal.status,
                priority: goal.priority,
                successMetrics: goal.successMetrics,
                trackingMethod: goal.trackingMethod,
                progress: goal.progress,
                skills: goal.skills,
                notes: goal.notes,
                createdAt: goal.createdAt,
                updatedAt: goal.updatedAt
            )
            context.insert(sdGoal)
            try DataManager.shared.save()

            sdGoals[goal.id] = sdGoal
            goals.insert(goal, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func addAchievement(_ achievement: Achievement) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            achievements.insert(achievement, at: 0)
            Theme.successHaptic()
            return
        }

        do {
            // Find linked goals
            let linkedGoals = achievement.goalIDs.compactMap { sdGoals[$0] }

            let sdAchievement = SDAchievement(
                id: achievement.id,
                title: achievement.title,
                achievementDescription: achievement.achievementDescription,
                dateAchieved: achievement.dateAchieved,
                impactStatement: achievement.impactStatement,
                goals: linkedGoals,
                evidenceLinks: achievement.evidenceLinks,
                tags: achievement.tags,
                visibility: achievement.visibility,
                createdAt: achievement.createdAt
            )
            context.insert(sdAchievement)
            try DataManager.shared.save()

            sdAchievements[achievement.id] = sdAchievement
            achievements.insert(achievement, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }
}
