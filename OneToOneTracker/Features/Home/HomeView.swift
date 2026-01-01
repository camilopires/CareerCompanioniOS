import SwiftUI

/// Main home screen with dashboard overview
struct HomeView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
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
                    QuickStatsSection(viewModel: viewModel)

                    // Action Items Section
                    ActionItemsSection(viewModel: viewModel)

                    // Upcoming 1:1 Card
                    if let nextMeeting = viewModel.nextMeeting {
                        UpcomingMeetingCard(meeting: nextMeeting, manager: viewModel.manager)
                    }

                    // Career Progress
                    CareerProgressCard(viewModel: viewModel)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Colors.backgroundGrouped)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
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

// MARK: - Quick Stats Section

private struct QuickStatsSection: View {
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

private struct StatItem: View {
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
    HomeView()
        .environmentObject(CloudKitManager.shared)
}
