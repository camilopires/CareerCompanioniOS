import Foundation
import SwiftData
import CloudKit

/// Central manager for SwiftData with CloudKit sync
/// Provides local-first storage with automatic iCloud sync when available
@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()

    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    @Published private(set) var isCloudKitAvailable = false
    @Published private(set) var lastSyncDate: Date?

    // MARK: - Initialization

    private init() {
        let schema = Schema([
            SDMeeting.self,
            SDManager.self,
            SDActionItem.self,
            SDCareerGoal.self,
            SDAchievement.self,
            SDAgendaItem.self
        ])

        // Configure with CloudKit sync to private database
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.careercompanion.app")
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        Task {
            await checkCloudKitStatus()
        }
    }

    // MARK: - CloudKit Status

    func checkCloudKitStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            isCloudKitAvailable = status == .available
        } catch {
            isCloudKitAvailable = false
        }
    }

    // MARK: - Fetch Helpers

    func fetchManagers(sortBy: [SortDescriptor<SDManager>] = [SortDescriptor(\.name)]) throws -> [SDManager] {
        let descriptor = FetchDescriptor<SDManager>(sortBy: sortBy)
        return try context.fetch(descriptor)
    }

    func fetchMeetings(
        predicate: Predicate<SDMeeting>? = nil,
        sortBy: [SortDescriptor<SDMeeting>] = [SortDescriptor(\.date, order: .reverse)]
    ) throws -> [SDMeeting] {
        var descriptor = FetchDescriptor<SDMeeting>(sortBy: sortBy)
        descriptor.predicate = predicate
        return try context.fetch(descriptor)
    }

    func fetchActionItems(
        predicate: Predicate<SDActionItem>? = nil,
        sortBy: [SortDescriptor<SDActionItem>] = [SortDescriptor(\.createdAt, order: .reverse)]
    ) throws -> [SDActionItem] {
        var descriptor = FetchDescriptor<SDActionItem>(sortBy: sortBy)
        descriptor.predicate = predicate
        return try context.fetch(descriptor)
    }

    func fetchCareerGoals(
        predicate: Predicate<SDCareerGoal>? = nil,
        sortBy: [SortDescriptor<SDCareerGoal>] = [SortDescriptor(\.updatedAt, order: .reverse)]
    ) throws -> [SDCareerGoal] {
        var descriptor = FetchDescriptor<SDCareerGoal>(sortBy: sortBy)
        descriptor.predicate = predicate
        return try context.fetch(descriptor)
    }

    func fetchAchievements(
        predicate: Predicate<SDAchievement>? = nil,
        sortBy: [SortDescriptor<SDAchievement>] = [SortDescriptor(\.dateAchieved, order: .reverse)]
    ) throws -> [SDAchievement] {
        var descriptor = FetchDescriptor<SDAchievement>(sortBy: sortBy)
        descriptor.predicate = predicate
        return try context.fetch(descriptor)
    }

    func fetchAgendaItems(
        for meeting: SDMeeting,
        sortBy: [SortDescriptor<SDAgendaItem>] = [SortDescriptor(\.order)]
    ) throws -> [SDAgendaItem] {
        let meetingID = meeting.id
        let predicate = #Predicate<SDAgendaItem> { item in
            item.meeting?.id == meetingID
        }
        let descriptor = FetchDescriptor<SDAgendaItem>(predicate: predicate, sortBy: sortBy)
        return try context.fetch(descriptor)
    }

    // MARK: - Save

    func save() throws {
        if context.hasChanges {
            try context.save()
            lastSyncDate = Date()
        }
    }

    // MARK: - Delete

    func delete<T: PersistentModel>(_ model: T) {
        context.delete(model)
    }

    func deleteAll<T: PersistentModel>(_ models: [T]) {
        for model in models {
            context.delete(model)
        }
    }
}
