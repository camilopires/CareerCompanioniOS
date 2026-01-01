import Foundation
import SwiftUI

/// ViewModel for action items list
@MainActor
final class ActionItemsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var items: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Filtered Items

    func filteredItems(for filter: ActionItemFilter) -> [ActionItem] {
        switch filter {
        case .open:
            return items.filter { $0.status != .completed }
                .sorted { sortByPriorityAndDue($0, $1) }
        case .completed:
            return items.filter { $0.status == .completed }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        case .overdue:
            return items.filter { $0.isOverdue }
                .sorted { sortByPriorityAndDue($0, $1) }
        case .all:
            return items.sorted { sortByPriorityAndDue($0, $1) }
        }
    }

    private func sortByPriorityAndDue(_ item1: ActionItem, _ item2: ActionItem) -> Bool {
        // Overdue first
        if item1.isOverdue != item2.isOverdue {
            return item1.isOverdue
        }
        // Then by priority
        if item1.priority.sortOrder != item2.priority.sortOrder {
            return item1.priority.sortOrder < item2.priority.sortOrder
        }
        // Then by due date
        if let date1 = item1.dueDate, let date2 = item2.dueDate {
            return date1 < date2
        }
        if item1.dueDate != nil { return true }
        if item2.dueDate != nil { return false }
        // Finally by created date
        return item1.createdAt > item2.createdAt
    }

    // MARK: - Data Loading

    func loadItems() async {
        isLoading = true
        error = nil

        do {
            let fetched: [ActionItem] = try await CloudKitManager.shared.fetch(
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )
            items = fetched
        } catch {
            self.error = error
            loadSampleData()
        }

        isLoading = false
    }

    // MARK: - Actions

    func addItem(_ item: ActionItem) async {
        do {
            let saved = try await CloudKitManager.shared.save(item)
            items.insert(saved, at: 0)
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func toggleComplete(_ item: ActionItem) async {
        var updated = item
        if updated.status == .completed {
            updated.reopen()
        } else {
            updated.markComplete()
        }

        do {
            let saved = try await CloudKitManager.shared.save(updated)
            if let index = items.firstIndex(where: { $0.id == saved.id }) {
                items[index] = saved
            }
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func updateItem(_ item: ActionItem) async {
        do {
            let saved = try await CloudKitManager.shared.save(item)
            if let index = items.firstIndex(where: { $0.id == saved.id }) {
                items[index] = saved
            }
        } catch {
            self.error = error
        }
    }

    func deleteItems(at offsets: IndexSet, filter: ActionItemFilter) async {
        let filtered = filteredItems(for: filter)
        let itemsToDelete = offsets.map { filtered[$0] }

        for item in itemsToDelete {
            do {
                try await CloudKitManager.shared.delete(item)
                items.removeAll { $0.id == item.id }
            } catch {
                self.error = error
            }
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        items = ActionItem.samples
    }
}
