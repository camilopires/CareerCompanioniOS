import SwiftUI

/// Empty state view for lists and sections with no content
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Colors.textTertiary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preset Empty States

extension EmptyState {
    /// Empty state for action items list
    static var noActionItems: EmptyState {
        EmptyState(
            icon: "checkmark.circle",
            title: "No Action Items",
            message: "Action items from your 1:1 meetings will appear here."
        )
    }

    /// Empty state for meetings list
    static var noMeetings: EmptyState {
        EmptyState(
            icon: "person.2",
            title: "No 1:1 Meetings",
            message: "Schedule your first 1:1 meeting to get started."
        )
    }

    /// Empty state for goals list
    static var noGoals: EmptyState {
        EmptyState(
            icon: "star",
            title: "No Career Goals",
            message: "Set your first career goal to start tracking your growth."
        )
    }

    /// Empty state for achievements list
    static var noAchievements: EmptyState {
        EmptyState(
            icon: "trophy",
            title: "No Achievements Yet",
            message: "Record your wins and accomplishments here."
        )
    }

    /// Empty state for agenda items
    static var noAgendaItems: EmptyState {
        EmptyState(
            icon: "list.bullet",
            title: "No Agenda Items",
            message: "Add topics you want to discuss in your 1:1."
        )
    }

    /// Empty state for search results
    static var noSearchResults: EmptyState {
        EmptyState(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search or filters."
        )
    }
}

// MARK: - Compact Empty State

/// A smaller empty state for inline use
struct CompactEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Colors.textTertiary)
                .accessibilityHidden(true)

            Text(message)
                .font(Typography.callout)
                .foregroundStyle(Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            EmptyState.noActionItems

            Divider()

            EmptyState(
                icon: "star.fill",
                title: "Set Your First Goal",
                message: "Career goals help you track progress towards your professional aspirations.",
                actionTitle: "Add Goal",
                action: { print("Add goal tapped") }
            )

            Divider()

            CompactEmptyState(
                icon: "doc.text",
                message: "No notes yet"
            )

            Divider()

            EmptyState.noSearchResults
        }
        .padding()
    }
}
