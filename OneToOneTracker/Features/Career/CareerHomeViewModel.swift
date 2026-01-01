import Foundation
import SwiftUI

/// ViewModel for career home screen
@MainActor
final class CareerHomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var goals: [CareerGoal] = []
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var error: Error?

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

        do {
            async let fetchedGoals: [CareerGoal] = CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)]
            )
            async let fetchedAchievements: [Achievement] = CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "dateAchieved", ascending: false)]
            )

            goals = try await fetchedGoals
            achievements = try await fetchedAchievements
        } catch {
            self.error = error
            loadSampleData()
        }

        isLoading = false
    }

    // MARK: - Actions

    func addGoal(_ goal: CareerGoal) async {
        do {
            let saved = try await CloudKitManager.shared.save(goal)
            goals.insert(saved, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func addAchievement(_ achievement: Achievement) async {
        do {
            let saved = try await CloudKitManager.shared.save(achievement)
            achievements.insert(saved, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        goals = CareerGoal.samples
        achievements = Achievement.samples
    }
}
