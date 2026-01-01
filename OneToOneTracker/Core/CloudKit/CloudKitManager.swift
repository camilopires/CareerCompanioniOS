import Foundation
import CloudKit
import Combine

/// Manages all CloudKit operations for the app
/// All data is stored in the user's PRIVATE iCloud database
/// This means data is:
/// - Encrypted and stored in the user's personal iCloud account
/// - Never shared with the app developer or any third parties
/// - Automatically synced across all the user's Apple devices
/// - Persisted even if the app is deleted (restored on reinstall)
@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    // MARK: - Published Properties

    @Published private(set) var isSignedIn = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var error: CloudKitError?

    // MARK: - Private Properties

    private let container: CKContainer
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Use the default container configured in entitlements
        self.container = CKContainer.default()
        Task {
            await checkAccountStatus()
        }
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            isSignedIn = status == .available
            if !isSignedIn {
                error = .notSignedIn
            }
        } catch {
            self.error = .accountError(error)
            isSignedIn = false
        }
    }

    // MARK: - Save

    /// Save a single record to the user's private iCloud database
    func save<T: CloudKitRecordable>(_ item: T) async throws -> T {
        guard isSignedIn else { throw CloudKitError.notSignedIn }

        isSyncing = true
        defer { isSyncing = false }

        let record = item.toCKRecord()

        do {
            let savedRecord = try await privateDatabase.save(record)
            guard let savedItem = T(record: savedRecord) else {
                throw CloudKitError.invalidRecord
            }
            lastSyncDate = Date()
            return savedItem
        } catch let ckError as CKError {
            throw mapCKError(ckError)
        }
    }

    /// Save multiple records in a batch operation
    func saveAll<T: CloudKitRecordable>(_ items: [T]) async throws -> [T] {
        guard isSignedIn else { throw CloudKitError.notSignedIn }
        guard !items.isEmpty else { return [] }

        isSyncing = true
        defer { isSyncing = false }

        let records = items.map { $0.toCKRecord() }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            var savedItems: [T] = []

            operation.perRecordSaveBlock = { _, result in
                switch result {
                case .success(let record):
                    if let item = T(record: record) {
                        savedItems.append(item)
                    }
                case .failure:
                    break
                }
            }

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    self.lastSyncDate = Date()
                    continuation.resume(returning: savedItems)
                case .failure(let error):
                    continuation.resume(throwing: self.mapCKError(error as? CKError ?? CKError(.internalError)))
                }
            }

            privateDatabase.add(operation)
        }
    }

    // MARK: - Fetch

    /// Fetch records of a specific type with an optional predicate
    func fetch<T: CloudKitRecordable>(
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = [],
        limit: Int? = nil
    ) async throws -> [T] {
        guard isSignedIn else { throw CloudKitError.notSignedIn }

        isSyncing = true
        defer { isSyncing = false }

        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        var allResults: [T] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let (results, nextCursor): ([T], CKQueryOperation.Cursor?) = try await fetchBatch(query: query, cursor: cursor, limit: limit)
            allResults.append(contentsOf: results)
            cursor = nextCursor

            if let limit, allResults.count >= limit {
                break
            }
        } while cursor != nil

        lastSyncDate = Date()
        return allResults
    }

    private func fetchBatch<T: CloudKitRecordable>(
        query: CKQuery,
        cursor: CKQueryOperation.Cursor?,
        limit: Int?
    ) async throws -> ([T], CKQueryOperation.Cursor?) {
        return try await withCheckedThrowingContinuation { continuation in
            let operation: CKQueryOperation
            if let cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                operation = CKQueryOperation(query: query)
            }

            if let limit {
                operation.resultsLimit = limit
            }

            var results: [T] = []

            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    if let item = T(record: record) {
                        results.append(item)
                    }
                case .failure:
                    break
                }
            }

            operation.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    continuation.resume(returning: (results, cursor))
                case .failure(let error):
                    continuation.resume(throwing: self.mapCKError(error as? CKError ?? CKError(.internalError)))
                }
            }

            privateDatabase.add(operation)
        }
    }

    /// Fetch a single record by ID
    func fetch<T: CloudKitRecordable>(id: UUID) async throws -> T? {
        guard isSignedIn else { throw CloudKitError.notSignedIn }

        let recordID = CKRecord.ID(recordName: id.uuidString)

        do {
            let record = try await privateDatabase.record(for: recordID)
            return T(record: record)
        } catch let ckError as CKError where ckError.code == .unknownItem {
            return nil
        } catch let ckError as CKError {
            throw mapCKError(ckError)
        }
    }

    // MARK: - Delete

    /// Delete a single record
    func delete(_ recordID: CKRecord.ID) async throws {
        guard isSignedIn else { throw CloudKitError.notSignedIn }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            lastSyncDate = Date()
        } catch let ckError as CKError {
            throw mapCKError(ckError)
        }
    }

    /// Delete a record by its model
    func delete<T: CloudKitRecordable>(_ item: T) async throws {
        try await delete(item.recordID)
    }

    /// Delete multiple records
    func deleteAll(_ recordIDs: [CKRecord.ID]) async throws {
        guard isSignedIn else { throw CloudKitError.notSignedIn }
        guard !recordIDs.isEmpty else { return }

        isSyncing = true
        defer { isSyncing = false }

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    self.lastSyncDate = Date()
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: self.mapCKError(error as? CKError ?? CKError(.internalError)))
                }
            }

            privateDatabase.add(operation)
        }
    }

    // MARK: - Subscriptions

    /// Subscribe to changes for real-time sync
    func subscribeToChanges<T: CloudKitRecordable>(for type: T.Type) async throws {
        guard isSignedIn else { throw CloudKitError.notSignedIn }

        let subscriptionID = "\(T.recordType)-changes"
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: T.recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        do {
            _ = try await privateDatabase.save(subscription)
        } catch let ckError as CKError where ckError.code == .serverRejectedRequest {
            // Subscription might already exist, which is fine
        } catch let ckError as CKError {
            throw mapCKError(ckError)
        }
    }

    // MARK: - Error Mapping

    private func mapCKError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .notAuthenticated:
            return .notSignedIn
        case .networkUnavailable, .networkFailure:
            return .networkError
        case .quotaExceeded:
            return .quotaExceeded
        case .serverRecordChanged:
            return .conflictError
        case .unknownItem:
            return .recordNotFound
        default:
            return .unknown(error)
        }
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case notSignedIn
    case networkError
    case quotaExceeded
    case conflictError
    case recordNotFound
    case invalidRecord
    case accountError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Please sign in to iCloud in Settings to sync your data."
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .quotaExceeded:
            return "Your iCloud storage is full. Please free up space to continue syncing."
        case .conflictError:
            return "A sync conflict occurred. Please try again."
        case .recordNotFound:
            return "The requested item could not be found."
        case .invalidRecord:
            return "Unable to process the data. Please try again."
        case .accountError(let error):
            return "iCloud account error: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
