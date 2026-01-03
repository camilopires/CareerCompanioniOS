import SwiftUI

/// Dashboard view for Individual Contributors
/// Shows personal 1:1s with manager, action items, and career progress
struct ICDashboardView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isDemoMode = AppSettings.shared.isDemoMode

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Privacy Banner (shown once)
                if viewModel.showPrivacyBanner {
                    PrivacyBanner {
                        withAnimation {
                            viewModel.dismissPrivacyBanner()
                        }
                    }
                }

                // Quick Stats
                ICQuickStatsSection(viewModel: viewModel)

                // iPad: Two-column layout for main content
                if isRegularWidth {
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        // Left column: Action Items + Career Progress
                        VStack(spacing: Spacing.sectionSpacing) {
                            ActionItemsSection(viewModel: viewModel)
                            CareerProgressCard(viewModel: viewModel)
                        }
                        .frame(maxWidth: .infinity)

                        // Right column: Meetings
                        VStack(spacing: Spacing.sectionSpacing) {
                            // Upcoming 1:1 with Manager
                            if let nextMeeting = viewModel.nextMeeting {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("With My Manager")
                                        .font(Typography.headline)
                                        .foregroundStyle(Colors.textPrimary)

                                    UpcomingMeetingCard(meeting: nextMeeting, manager: viewModel.manager)
                                }
                            }

                            // Other 1:1s Section
                            if !viewModel.upcomingOtherMeetings.isEmpty {
                                OtherMeetingsSection(viewModel: viewModel)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // iPhone: Single column layout
                    ActionItemsSection(viewModel: viewModel)

                    // Upcoming 1:1 with Manager
                    if let nextMeeting = viewModel.nextMeeting {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("With My Manager")
                                .font(Typography.headline)
                                .foregroundStyle(Colors.textPrimary)

                            UpcomingMeetingCard(meeting: nextMeeting, manager: viewModel.manager)
                        }
                    }

                    // Other 1:1s Section
                    if !viewModel.upcomingOtherMeetings.isEmpty {
                        OtherMeetingsSection(viewModel: viewModel)
                    }

                    // Career Progress
                    CareerProgressCard(viewModel: viewModel)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let newValue = AppSettings.shared.isDemoMode
            if newValue != isDemoMode {
                isDemoMode = newValue
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}

// MARK: - Privacy Banner

private struct PrivacyBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Colors.success)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Data is Private")
                        .font(Typography.headline)

                    Text("All your data is stored securely in your personal iCloud account. It syncs across your devices and is never shared with anyone.")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Colors.textTertiary)
                }
                .accessibilityLabel("Dismiss")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - IC Quick Stats Section

private struct ICQuickStatsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.sm) {
            StatItem(
                value: "\(viewModel.openActionItemsCount)",
                label: "Open",
                icon: "circle",
                color: viewModel.openActionItemsCount > 0 ? .accentColor : Colors.textTertiary
            )

            StatItem(
                value: "\(viewModel.completedThisWeekCount)",
                label: "Done",
                icon: "checkmark.circle.fill",
                color: Colors.success
            )

            StatItem(
                value: "\(viewModel.meetingStreak)",
                label: "Streak",
                icon: "flame.fill",
                color: viewModel.meetingStreak > 0 ? .orange : Colors.textTertiary
            )

            StatItem(
                value: "\(viewModel.activeGoalsCount)",
                label: "Goals",
                icon: "star.fill",
                color: .purple
            )
        }
    }
}

// MARK: - Other Meetings Section

private struct OtherMeetingsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Other 1:1s")
                .font(Typography.headline)
                .foregroundStyle(Colors.textPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.upcomingOtherMeetings) { meeting in
                    if let person = viewModel.person(for: meeting) {
                        OtherMeetingCard(meeting: meeting, person: person)
                    }
                }
            }
        }
    }
}

// MARK: - Other Meeting Card

private struct OtherMeetingCard: View {
    let meeting: Meeting
    let person: Manager

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Person info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(person.name)
                            .font(Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Colors.textPrimary)

                        Text(person.relationshipType)
                            .font(Typography.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorForRelationshipType(person.relationshipType))
                            .cornerRadius(4)
                    }

                    HStack(spacing: Spacing.xs) {
                        Text(meeting.meetingType)
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)

                        Text("•")
                            .foregroundStyle(Colors.textTertiary)

                        Text(meeting.date.formatted(date: .abbreviated, time: .shortened))
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Colors.textTertiary)
            }
        }
    }

    private func colorForRelationshipType(_ type: String) -> Color {
        switch type {
        case "Mentor": return .purple
        case "Peer": return .orange
        case "Stakeholder": return .yellow
        case "Skip-Level Manager": return .teal
        case "Cross-Team Partner": return .indigo
        case "External Coach": return .mint
        default: return .gray
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Colors.textPrimary)

            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ICDashboardView()
    }
    .environmentObject(CloudKitManager.shared)
}
