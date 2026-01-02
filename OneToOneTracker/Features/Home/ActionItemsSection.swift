import SwiftUI

/// Section displaying action items on the home screen
struct ActionItemsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Action Items")
                    .font(Typography.headline)

                Spacer()

                if !viewModel.openActionItems.isEmpty {
                    NavigationLink(destination: ActionItemsListView()) {
                        Text("See All")
                            .font(Typography.callout)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            // Content
            if viewModel.openActionItems.isEmpty {
                CompactEmptyState(
                    icon: "checkmark.circle",
                    message: "No open action items"
                )
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.openActionItems.prefix(5)) { item in
                        ActionItemRow(
                            item: item,
                            onComplete: {
                                Task {
                                    await viewModel.completeActionItem(item)
                                }
                            }
                        )

                        if item.id != viewModel.openActionItems.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, Spacing.touchTarget + Spacing.md)
                        }
                    }
                }
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
        }
    }
}

// MARK: - Action Item Row

struct ActionItemRow: View {
    let item: ActionItem
    let onComplete: () -> Void

    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Complete button
            Button(action: {
                isCompleting = true
                onComplete()
                Theme.successHaptic()
                UIAccessibility.post(notification: .announcement, argument: "\(item.title) marked complete")
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(item.isOverdue ? Colors.error : Colors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleting {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
            .accessibilityLabel("Mark as complete")

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)
                    .foregroundStyle(Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    // Due date
                    if let formattedDate = item.formattedDueDate {
                        Label(formattedDate, systemImage: "calendar")
                            .font(Typography.caption1)
                            .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                    }

                    // Priority indicator
                    if item.priority == .high {
                        Label("High", systemImage: item.priority.icon)
                            .font(Typography.caption1)
                            .foregroundStyle(item.priority.color)
                    }

                    // Owner
                    if item.owner == .manager {
                        Label("Manager", systemImage: "person.badge.shield.checkmark")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
                .labelStyle(CompactLabelStyle())
            }

            Spacer()

            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Colors.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [item.title]
        if let date = item.formattedDueDate {
            parts.append("Due \(date)")
        }
        if item.isOverdue {
            parts.append("Overdue")
        }
        if item.priority == .high {
            parts.append("High priority")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Compact Label Style

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Preview

#Preview("Action Items Section") {
    NavigationStack {
        ScrollView {
            ActionItemsSection(viewModel: {
                let vm = HomeViewModel()
                return vm
            }())
            .padding()
        }
    }
}

#Preview("Action Item Row") {
    let previewItems = [
        ActionItem(title: "Review Q4 objectives", priority: .high),
        ActionItem(
            title: "Update documentation",
            dueDate: Date().addingTimeInterval(-86400), // Overdue
            priority: .medium
        ),
        ActionItem(title: "Follow up on budget request", priority: .high, owner: .manager)
    ]

    return VStack(spacing: 0) {
        ActionItemRow(item: previewItems[0], onComplete: {})
        Divider()
        ActionItemRow(item: previewItems[1], onComplete: {})
        Divider()
        ActionItemRow(item: previewItems[2], onComplete: {})
    }
    .background(Colors.backgroundSecondary)
    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    .padding()
}
