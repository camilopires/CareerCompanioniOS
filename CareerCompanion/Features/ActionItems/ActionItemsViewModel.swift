import Foundation
import SwiftUI
import SwiftData

/// ViewModel for action items list
@MainActor
final class ActionItemsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var items: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var context: ModelContext { DataManager.shared.context }
    private var sdItems: [UUID: SDActionItem] = [:]

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

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            items = DemoDataProvider.actionItems
            isLoading = false
            return
        }

        do {
            let fetched = try DataManager.shared.fetchActionItems()
            items = fetched.map { $0.toActionItem() }
            sdItems = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Actions

    func addItem(_ item: ActionItem) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            items.insert(item, at: 0)
            Theme.successHaptic()
            return
        }

        do {
            let sdItem = SDActionItem(
                id: item.id,
                meeting: nil,
                title: item.title,
                itemDescription: item.itemDescription,
                dueDate: item.dueDate,
                priority: item.priority,
                status: item.status,
                owner: item.owner,
                links: item.links,
                createdAt: item.createdAt
            )
            context.insert(sdItem)
            try DataManager.shared.save()

            sdItems[item.id] = sdItem
            items.insert(item, at: 0)
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

        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updated
            }
            Theme.successHaptic()
            return
        }

        do {
            if let sdItem = sdItems[item.id] {
                sdItem.update(from: updated)
                try DataManager.shared.save()
            }

            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updated
            }
            Theme.successHaptic()
        } catch {
            self.error = error
            Theme.errorHaptic()
        }
    }

    func updateItem(_ item: ActionItem) async {
        // In demo mode, only update in-memory
        if AppSettings.shared.isDemoMode {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
            return
        }

        do {
            if let sdItem = sdItems[item.id] {
                sdItem.update(from: item)
                try DataManager.shared.save()
            }

            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
        } catch {
            self.error = error
        }
    }

    func deleteItems(at offsets: IndexSet, filter: ActionItemFilter) async {
        let filtered = filteredItems(for: filter)
        let itemsToDelete = offsets.map { filtered[$0] }

        for item in itemsToDelete {
            // In demo mode, only update in-memory
            if AppSettings.shared.isDemoMode {
                items.removeAll { $0.id == item.id }
                continue
            }

            do {
                if let sdItem = sdItems[item.id] {
                    context.delete(sdItem)
                    try DataManager.shared.save()
                    sdItems.removeValue(forKey: item.id)
                }
                items.removeAll { $0.id == item.id }
            } catch {
                self.error = error
            }
        }
    }
}
