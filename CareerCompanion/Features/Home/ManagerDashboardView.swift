import SwiftUI

/// Dashboard view for Managers
/// Shows team overview, upcoming 1:1s with reports, and team metrics
struct ManagerDashboardView: View {
    @StateObject private var viewModel = ManagerDashboardViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Team Quick Stats
                TeamQuickStatsSection(viewModel: viewModel)

                // Team Health Card
                TeamHealthSection(viewModel: viewModel)

                // iPad: Two-column layout for main content
                if isRegularWidth {
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        // Left column: Meetings + Other 1:1s
                        VStack(spacing: Spacing.sectionSpacing) {
                            TeamMeetingsSection(viewModel: viewModel)

                            if !viewModel.upcomingOtherMeetings.isEmpty {
                                ManagerOtherMeetingsSection(viewModel: viewModel)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Right column: Action Items + Team Grid
                        VStack(spacing: Spacing.sectionSpacing) {
                            TeamActionItemsSection(viewModel: viewModel)
                            TeamMembersGridSection(viewModel: viewModel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // iPhone: Single column layout
                    TeamMeetingsSection(viewModel: viewModel)
                    TeamActionItemsSection(viewModel: viewModel)
                    TeamMembersGridSection(viewModel: viewModel)

                    if !viewModel.upcomingOtherMeetings.isEmpty {
                        ManagerOtherMeetingsSection(viewModel: viewModel)
                    }
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
    }
}

// MARK: - Manager Dashboard ViewModel

@MainActor
final class ManagerDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var teamMembers: [Manager] = []
    @Published var otherPeople: [Manager] = []
    @Published var allMeetings: [Meeting] = []
    @Published var upcomingOtherMeetings: [Meeting] = []
    @Published var teamActionItems: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var teamMemberCount: Int {
        teamMembers.count
    }

    var upcomingMeetings: [Meeting] {
        allMeetings.filter { $0.isUpcoming }.sorted { $0.date < $1.date }
    }

    var upcomingMeetingCount: Int {
        upcomingMeetings.count
    }

    var overdueActionItemsCount: Int {
        teamActionItems.filter { $0.isOverdue && $0.status != .completed }.count
    }

    var openActionItemsCount: Int {
        teamActionItems.filter { $0.status != .completed }.count
    }

    var nextMeeting: Meeting? {
        upcomingMeetings.first
    }

    var recentMeetings: [Meeting] {
        Array(upcomingMeetings.prefix(3))
    }

    // MARK: - Team Health Metrics

    var completedMeetingsThisMonth: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return allMeetings.filter { meeting in
            meeting.status == .completed && meeting.date >= startOfMonth
        }.count
    }

    var averageMeetingCadenceDescription: String {
        guard teamMemberCount > 0, completedMeetingsThisMonth > 0 else {
            return "No data"
        }
        let meetingsPerPerson = Double(completedMeetingsThisMonth) / Double(teamMemberCount)
        if meetingsPerPerson >= 4 {
            return "Weekly"
        } else if meetingsPerPerson >= 2 {
            return "Bi-weekly"
        } else if meetingsPerPerson >= 1 {
            return "Monthly"
        } else {
            return "Infrequent"
        }
    }

    var actionItemCompletionRate: Int {
        let total = teamActionItems.count
        guard total > 0 else { return 100 }
        let completed = teamActionItems.filter { $0.status == .completed }.count
        return Int((Double(completed) / Double(total)) * 100)
    }

    var teamMembersNeedingAttention: [Manager] {
        let twoWeeksAgo = Date().addingTimeInterval(-14 * 24 * 60 * 60)
        return teamMembers.filter { member in
            let lastMeeting = lastMeetingDate(for: member)
            return lastMeeting == nil || lastMeeting! < twoWeeksAgo
        }
    }

    // MARK: - Per-Member Stats

    func lastMeetingDate(for member: Manager) -> Date? {
        allMeetings
            .filter { $0.managerID == member.id && $0.status == .completed }
            .sorted { $0.date > $1.date }
            .first?.date
    }

    func nextMeetingDate(for member: Manager) -> Date? {
        allMeetings
            .filter { $0.managerID == member.id && $0.isUpcoming }
            .sorted { $0.date < $1.date }
            .first?.date
    }

    func meetingCount(for member: Manager) -> Int {
        allMeetings.filter { $0.managerID == member.id }.count
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Use demo data if in demo mode
        if AppSettings.shared.isDemoMode {
            let allPeople = DemoDataProvider.managers
            teamMembers = allPeople.filter { $0.isDirectReport }
            otherPeople = allPeople.filter { $0.isOtherRelationship }

            let allDemoMeetings = DemoDataProvider.meetings.filter { $0.perspective == .asManager }
            allMeetings = allDemoMeetings
            teamActionItems = DemoDataProvider.actionItems.filter { $0.owner == .manager }

            // Get upcoming meetings with other people
            let otherPersonIDs = Set(otherPeople.map { $0.id })
            upcomingOtherMeetings = allDemoMeetings
                .filter { $0.status == .scheduled && otherPersonIDs.contains($0.managerID) }
                .sorted { $0.date < $1.date }
                .prefix(3)
                .map { $0 }

            isLoading = false
            return
        }

        do {
            // Fetch all people
            async let fetchedAllPeople: [Manager] = CloudKitManager.shared.fetch()

            // Fetch all meetings (as manager)
            async let fetchedMeetings: [Meeting] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "perspective == %@", MeetingPerspective.asManager.rawValue),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )

            // Fetch action items assigned to manager
            async let fetchedActionItems: [ActionItem] = CloudKitManager.shared.fetch(
                predicate: NSPredicate(format: "owner == %@", Owner.manager.rawValue)
            )

            let allPeople = try await fetchedAllPeople
            teamMembers = allPeople.filter { $0.isDirectReport }
            otherPeople = allPeople.filter { $0.isOtherRelationship }

            allMeetings = try await fetchedMeetings
            teamActionItems = try await fetchedActionItems

            // Get upcoming meetings with other people
            let otherPersonIDs = Set(otherPeople.map { $0.id })
            upcomingOtherMeetings = allMeetings
                .filter { $0.status == .scheduled && otherPersonIDs.contains($0.managerID) }
                .sorted { $0.date < $1.date }
                .prefix(3)
                .map { $0 }

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

    func otherPerson(for meeting: Meeting) -> Manager? {
        otherPeople.first { $0.id == meeting.managerID }
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

// MARK: - Team Health Section

private struct TeamHealthSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Team Health")
                .font(Typography.headline)

            HStack(spacing: Spacing.md) {
                // Meeting Cadence
                HealthMetricCard(
                    icon: "calendar.badge.clock",
                    title: "Avg. Cadence",
                    value: viewModel.averageMeetingCadenceDescription,
                    color: .accentColor
                )

                // Completion Rate
                HealthMetricCard(
                    icon: "checkmark.circle",
                    title: "Completion",
                    value: "\(viewModel.actionItemCompletionRate)%",
                    color: viewModel.actionItemCompletionRate >= 80 ? Colors.success :
                           viewModel.actionItemCompletionRate >= 50 ? .orange : Colors.error
                )

                // Needs Attention
                HealthMetricCard(
                    icon: "exclamationmark.triangle",
                    title: "Need 1:1",
                    value: "\(viewModel.teamMembersNeedingAttention.count)",
                    color: viewModel.teamMembersNeedingAttention.isEmpty ? Colors.success : Colors.warning
                )
            }
        }
    }
}

private struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.headline)
                .foregroundStyle(Colors.textPrimary)

            Text(title)
                .font(Typography.caption2)
                .foregroundStyle(Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
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

// MARK: - Team Members Grid Section

private struct TeamMembersGridSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showingNewMeeting = false
    @State private var showingAddPerson = false
    @State private var selectedMember: Manager?

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
                Button {
                    showingAddPerson = true
                } label: {
                    CompactEmptyState(
                        icon: "person.badge.plus",
                        message: "Add Your First Team Member"
                    )
                    .background(Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
                }
                .buttonStyle(.plain)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.sm) {
                    ForEach(viewModel.teamMembers) { member in
                        EnhancedTeamMemberCard(
                            member: member,
                            lastMeeting: viewModel.lastMeetingDate(for: member),
                            nextMeeting: viewModel.nextMeetingDate(for: member),
                            meetingCount: viewModel.meetingCount(for: member),
                            needsAttention: viewModel.teamMembersNeedingAttention.contains { $0.id == member.id },
                            onScheduleTapped: {
                                selectedMember = member
                                showingNewMeeting = true
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewMeeting) {
            if let member = selectedMember {
                QuickScheduleMeetingView(member: member)
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonView { _ in
                // Refresh will happen automatically via CloudKit sync
            }
        }
    }
}

private struct EnhancedTeamMemberCard: View {
    let member: Manager
    let lastMeeting: Date?
    let nextMeeting: Date?
    let meetingCount: Int
    let needsAttention: Bool
    let onScheduleTapped: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Avatar with badge
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(member.name.prefix(1).uppercased())
                            .font(Typography.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentColor)
                    }

                if needsAttention {
                    Circle()
                        .fill(Colors.warning)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 4, y: -4)
                }
            }

            Text(member.name)
                .font(Typography.callout)
                .foregroundStyle(Colors.textPrimary)
                .lineLimit(1)

            // Meeting info
            if let next = nextMeeting {
                Text("Next: \(next.formatted(.dateTime.month().day()))")
                    .font(Typography.caption2)
                    .foregroundStyle(Colors.success)
            } else if let last = lastMeeting {
                Text("Last: \(last.formatted(.relative(presentation: .named)))")
                    .font(Typography.caption2)
                    .foregroundStyle(needsAttention ? Colors.warning : Colors.textSecondary)
            } else {
                Text("No meetings yet")
                    .font(Typography.caption2)
                    .foregroundStyle(Colors.textTertiary)
            }

            // Quick action button
            Button(action: onScheduleTapped) {
                Label("Schedule", systemImage: "calendar.badge.plus")
                    .font(Typography.caption1)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        .overlay {
            if needsAttention {
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(Colors.warning, lineWidth: 1)
            }
        }
    }
}

// MARK: - Quick Schedule Meeting View

struct QuickScheduleMeetingView: View {
    @Environment(\.dismiss) private var dismiss
    let member: Manager
    @State private var date = Date().addingTimeInterval(86400 * 7) // Default to 1 week from now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(member.name.prefix(1).uppercased())
                                    .font(Typography.headline)
                                    .foregroundStyle(Color.accentColor)
                            }

                        Text(member.name)
                            .font(Typography.body)
                    }
                } header: {
                    Text("Team Member")
                }

                Section {
                    DatePicker("Date & Time", selection: $date)
                } header: {
                    Text("Meeting Details")
                }
            }
            .navigationTitle("Schedule 1:1")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMeeting()
                    }
                }
            }
        }
    }

    private func createMeeting() {
        let meeting = Meeting(
            managerID: member.id,
            date: date,
            perspective: .asManager
        )

        Task {
            if AppSettings.shared.isDemoMode {
                dismiss()
                return
            }

            _ = try? await CloudKitManager.shared.save(meeting)
            dismiss()
        }
    }
}

// MARK: - Manager Other Meetings Section

private struct ManagerOtherMeetingsSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Other 1:1s")
                .font(Typography.headline)

            VStack(spacing: 0) {
                ForEach(viewModel.upcomingOtherMeetings) { meeting in
                    if let person = viewModel.otherPerson(for: meeting) {
                        ManagerOtherMeetingRow(meeting: meeting, person: person)

                        if meeting.id != viewModel.upcomingOtherMeetings.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .background(Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
    }
}

private struct ManagerOtherMeetingRow: View {
    let meeting: Meeting
    let person: Manager

    var body: some View {
        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
            HStack(spacing: Spacing.md) {
                // Avatar placeholder
                Circle()
                    .fill(colorForRelationshipType(person.relationshipType).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(person.name.prefix(1).uppercased())
                            .font(Typography.headline)
                            .foregroundStyle(colorForRelationshipType(person.relationshipType))
                    }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(person.name)
                            .font(Typography.body)
                            .foregroundStyle(Colors.textPrimary)

                        Text(person.relationshipType)
                            .font(Typography.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
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

                        Text(meeting.date.formatted(.relative(presentation: .named)))
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Colors.textTertiary)
            }
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ManagerDashboardView()
    }
    .environmentObject(CloudKitManager.shared)
}
