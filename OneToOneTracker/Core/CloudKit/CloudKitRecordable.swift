import Foundation
import CloudKit

/// Protocol for models that can be saved to and fetched from CloudKit
/// All data is stored in the user's private iCloud database - never shared with anyone
protocol CloudKitRecordable: Identifiable, Hashable {
    /// The CloudKit record type name
    static var recordType: String { get }

    /// The unique identifier
    var id: UUID { get }

    /// The CloudKit record ID
    var recordID: CKRecord.ID { get }

    /// Convert the model to a CKRecord for saving
    func toCKRecord() -> CKRecord

    /// Initialize from a CKRecord
    init?(record: CKRecord)
}

extension CloudKitRecordable {
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }
}

// MARK: - CKRecord Extensions

extension CKRecord {
    /// Safely get a string value
    func string(for key: String) -> String? {
        self[key] as? String
    }

    /// Safely get an optional string, returning empty string if nil
    func stringOrEmpty(for key: String) -> String {
        self[key] as? String ?? ""
    }

    /// Safely get a date value
    func date(for key: String) -> Date? {
        self[key] as? Date
    }

    /// Safely get an integer value
    func integer(for key: String) -> Int {
        (self[key] as? Int64).map(Int.init) ?? 0
    }

    /// Safely get a boolean value (stored as Int64 in CloudKit)
    func bool(for key: String) -> Bool {
        (self[key] as? Int64) == 1
    }

    /// Safely get a string array from JSON data
    func stringArray(for key: String) -> [String] {
        guard let data = self[key] as? Data,
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }

    /// Safely get a URL array from JSON data
    func urlArray(for key: String) -> [URL] {
        guard let data = self[key] as? Data,
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return strings.compactMap { URL(string: $0) }
    }

    /// Safely get a reference
    func reference(for key: String) -> CKRecord.Reference? {
        self[key] as? CKRecord.Reference
    }

    /// Safely get reference array
    func referenceArray(for key: String) -> [CKRecord.Reference] {
        self[key] as? [CKRecord.Reference] ?? []
    }

    /// Set a string array as JSON data
    func setStringArray(_ array: [String], for key: String) {
        if let data = try? JSONEncoder().encode(array) {
            self[key] = data
        }
    }

    /// Set a URL array as JSON data (stores as string array)
    func setURLArray(_ urls: [URL], for key: String) {
        let strings = urls.map { $0.absoluteString }
        setStringArray(strings, for: key)
    }

    /// Set a boolean value (stored as Int64)
    func setBool(_ value: Bool, for key: String) {
        self[key] = value ? 1 : 0
    }
}
