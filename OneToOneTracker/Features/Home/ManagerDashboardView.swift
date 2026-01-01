import SwiftUI

/// Dashboard view for Managers
/// Shows team overview, upcoming 1:1s with reports, and team metrics
struct ManagerDashboardView: View {
    @StateObject private var viewModel = ManagerDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Team Quick Stats
                TeamQuickStatsSection(viewModel: viewModel)

                // Upcoming 1:1s with Team
                TeamMeetingsSection(viewModel: viewModel)

                // Team Action Items
                TeamActionItemsSection(viewModel: viewModel)

                // Team Members
                TeamMembersSection(viewModel: viewModel)
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
    }
}

// MARK: - Manager Dashboard ViewModel

@MainActor
final class ManagerDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var teamMembers: [Manager] = []
    @Published var upcomingMeetings: [Meeting] = []
    @Published var teamActionItems: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var teamMemberCount: Int {
        teamMembers.count
    }

    var upcomingMeetingCount: Int {
        upcomingMeetings.filter { $0.isUpcoming }.count
    }

    var overdueActionItemsCount: Int {
        teamActionItems.filter { $0.isOverdue && $0.status != .completed }.count
    }

    var openActionItemsCount: Int {
        teamActionItems.filter { $0.status != .completed }.count
    }

    var nextMeeting: Meeting? {
        upcomingMeetings
            .filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
            .first
    }

    var recentMeetings: [Meeting] {
        upcomingMeetings
            .filter { $0.isUpcoming }
            .sorted { $0.date < $1.date }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch team members (direct reports)
            async let fetchedTeamMembers: [Manager] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "relationship == %@", ManagerRelationship.directReport.rawValue)
            )

            // Fetch upcoming meetings (as manager)
            async let fetchedMeetings: [Meeting] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "perspective == %@ AND status == %@",
                    MeetingPerspective.asManager.rawValue,
                    MeetingStatus.scheduled.rawValue),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)]
            )

            // Fetch action items assigned to manager
            async let fetchedActionItems: [ActionItem] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "owner == %@", Owner.manager.rawValue)
            )

            teamMembers = try await fetchedTeamMembers
            upcomingMeetings = try await fetchedMeetings
            teamActionItems = try await fetchedActionItems

        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    func teamMember(for meeting: Meeting) -> Manager? {
        teamMembers.first { $0.id == meeting.managerID }
    }
}

// MARK: - Team Quick Stats Section

private struct TeamQuickStatsSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.sm) {
            StatItem(
                value: "\(viewModel.teamMemberCount)",
                label: "Team",
                icon: "person.3.fill",
                color: .accentColor
            )

            StatItem(
                value: "\(viewModel.upcomingMeetingCount)",
                label: "1:1s",
                icon: "calendar",
                color: viewModel.upcomingMeetingCount > 0 ? Colors.success : Colors.textTertiary
            )

            StatItem(
                value: "\(viewModel.openActionItemsCount)",
                label: "Actions",
                icon: "checklist",
                color: viewModel.openActionItemsCount > 0 ? .orange : Colors.textTertiary
            )

            StatItem(
                value: "\(viewModel.overdueActionItemsCount)",
                label: "Overdue",
                icon: "exclamationmark.circle.fill",
                color: viewModel.overdueActionItemsCount > 0 ? Colors.error : Colors.textTertiary
            )
        }
    }
}

// MARK: - Team Meetings Section

private struct TeamMeetingsSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Upcoming 1:1s")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: MeetingsListView()) {
                    Text("See All")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            if viewModel.recentMeetings.isEmpty {
                CompactEmptyState(
                    icon: "calendar.badge.plus",
                    message: "No upcoming 1:1s scheduled"
                )
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentMeetings) { meeting in
                        TeamMeetingRow(
                            meeting: meeting,
                            teamMember: viewModel.teamMember(for: meeting)
                        )

                        if meeting.id != viewModel.recentMeetings.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
        }
    }
}

private struct TeamMeetingRow: View {
    let meeting: Meeting
    let teamMember: Manager?

    var body: some View {
        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
            HStack(spacing: Spacing.md) {
                // Avatar placeholder
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(teamMember?.name.prefix(1).uppercased() ?? "?")
                            .font(Typography.headline)
                            .foregroundStyle(Color.accentColor)
                    }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(teamMember?.name ?? "Team Member")
                        .font(Typography.body)
                        .foregroundStyle(Colors.textPrimary)

                    Text(meeting.formattedDate)
                        .font(Typography.caption1)
                        .foregroundStyle(Colors.textSecondary)
                }

                Spacer()

                // Time until
                Text(meeting.date.formatted(.relative(presentation: .named)))
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Colors.textTertiary)
            }
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Action Items Section

private struct TeamActionItemsSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Your Action Items")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: ActionItemsListView()) {
                    Text("See All")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            let openItems = viewModel.teamActionItems.filter { $0.status != .completed }

            if openItems.isEmpty {
                CompactEmptyState(
                    icon: "checkmark.circle",
                    message: "No open action items"
                )
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            } else {
                VStack(spacing: 0) {
                    ForEach(openItems.prefix(3)) { item in
                        ManagerActionItemRow(item: item)

                        if item.id != openItems.prefix(3).last?.id {
                            Divider()
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            }
        }
    }
}

private struct ManagerActionItemRow: View {
    let item: ActionItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)
                    .foregroundStyle(Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    if let formattedDate = item.formattedDueDate {
                        Label(formattedDate, systemImage: "calendar")
                            .font(Typography.caption1)
                            .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                    }

                    if item.priority == .high {
                        Label("High", systemImage: item.priority.icon)
                            .font(Typography.caption1)
                            .foregroundStyle(item.priority.color)
                    }
                }
                .labelStyle(CompactLabelStyle())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Colors.textTertiary)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Team Members Section

private struct TeamMembersSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Your Team")
                    .font(Typography.headline)

                Spacer()

                NavigationLink(destination: PeopleListView()) {
                    Text("Manage")
                        .font(Typography.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }

            if viewModel.teamMembers.isEmpty {
                CompactEmptyState(
                    icon: "person.badge.plus",
                    message: "Add team members in Settings"
                )
                .background(Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    ForEach(viewModel.teamMembers) { member in
                        TeamMemberCard(member: member)
                    }
                }
            }
        }
    }
}

private struct TeamMemberCard: View {
    let member: Manager

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(member.name.prefix(1).uppercased())
                        .font(Typography.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                }

            Text(member.name)
                .font(Typography.callout)
                .foregroundStyle(Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ManagerDashboardView()
    }
    .environmentObject(CloudKitManager.shared)
}
