import SwiftUI

/// Detailed view of an action item
struct ActionItemDetailView: View {
    @State private var item: ActionItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false

    init(item: ActionItem) {
        self._item = State(initialValue: item)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Status card
                StatusCard(item: item, onToggleComplete: toggleComplete)

                // Details
                DetailsSection(item: $item, isEditing: isEditing)

                // Links
                if !item.links.isEmpty || isEditing {
                    LinksSection(links: $item.links, isEditing: isEditing)
                }

                // Delete button
                if isEditing {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Action Item", systemImage: "trash")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle(isEditing ? "Edit Item" : "Action Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
        .confirmationDialog(
            "Delete Action Item",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func toggleComplete() {
        if item.status == .completed {
            item.reopen()
        } else {
            item.markComplete()
        }
        saveChanges()
    }

    private func saveChanges() {
        Task {
            do {
                _ = try await CloudKitManager.shared.save(item)
                Theme.successHaptic()
            } catch {
                Theme.errorHaptic()
            }
        }
    }

    private func deleteItem() {
        Task {
            do {
                try await CloudKitManager.shared.delete(item)
                dismiss()
            } catch {
                Theme.errorHaptic()
            }
        }
    }
}

// MARK: - Status Card

private struct StatusCard: View {
    let item: ActionItem
    let onToggleComplete: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(item.title)
                    .font(Typography.title3)
                    .fontWeight(.semibold)

                HStack(spacing: Spacing.lg) {
                    // Status
                    Label(item.status.displayName, systemImage: item.status.icon)
                        .foregroundStyle(item.status.color)

                    // Priority
                    Label(item.priority.displayName, systemImage: item.priority.icon)
                        .foregroundStyle(item.priority.color)

                    Spacer()
                }
                .font(Typography.callout)

                if item.status == .completed {
                    Button(action: onToggleComplete) {
                        Text("Reopen")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(action: onToggleComplete) {
                        Text("Mark Complete")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
}

// MARK: - Details Section

private struct DetailsSection: View {
    @Binding var item: ActionItem
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .font(Typography.headline)

            Card {
                VStack(spacing: Spacing.md) {
                    // Description
                    if isEditing {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)

                            TextField("Add description...", text: $item.itemDescription, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    } else if !item.itemDescription.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)

                            Text(item.itemDescription)
                                .font(Typography.body)
                        }
                    }

                    Divider()

                    // Due date
                    HStack {
                        Label("Due Date", systemImage: "calendar")
                            .font(Typography.body)

                        Spacer()

                        if isEditing {
                            DatePicker("", selection: Binding(
                                get: { item.dueDate ?? Date() },
                                set: { item.dueDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        } else {
                            Text(item.formattedDueDate ?? "Not set")
                                .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                        }
                    }

                    Divider()

                    // Priority
                    HStack {
                        Label("Priority", systemImage: "flag")
                            .font(Typography.body)

                        Spacer()

                        if isEditing {
                            Picker("", selection: $item.priority) {
                                ForEach(Priority.allCases) { priority in
                                    Text(priority.displayName).tag(priority)
                                }
                            }
                            .labelsHidden()
                        } else {
                            Label(item.priority.displayName, systemImage: item.priority.icon)
                                .foregroundStyle(item.priority.color)
                        }
                    }

                    Divider()

                    // Owner
                    HStack {
                        Label("Owner", systemImage: "person")
                            .font(Typography.body)

                        Spacer()

                        if isEditing {
                            Picker("", selection: $item.owner) {
                                ForEach(Owner.allCases) { owner in
                                    Text(owner.displayName).tag(owner)
                                }
                            }
                            .labelsHidden()
                        } else {
                            Label(item.owner.displayName, systemImage: item.owner.icon)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Links Section

private struct LinksSection: View {
    @Binding var links: [URL]
    let isEditing: Bool

    @State private var newLink = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Links")
                .font(Typography.headline)

            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(links, id: \.self) { url in
                        HStack {
                            Link(destination: url) {
                                Label(url.host ?? url.absoluteString, systemImage: "link")
                                    .font(Typography.body)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if isEditing {
                                Button(action: { links.removeAll { $0 == url } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Colors.textTertiary)
                                }
                            }
                        }
                    }

                    if isEditing {
                        HStack {
                            TextField("Add link...", text: $newLink)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                .autocapitalization(.none)

                            if !newLink.isEmpty {
                                Button(action: addLink) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func addLink() {
        var urlString = newLink
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        if let url = URL(string: urlString) {
            links.append(url)
            newLink = ""
        }
    }
}

// MARK: - Preview

#Preview("Action Item Detail") {
    NavigationStack {
        ActionItemDetailView(item: ActionItem.sample)
    }
}
