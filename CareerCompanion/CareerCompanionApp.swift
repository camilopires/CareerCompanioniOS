import SwiftUI
import CloudKit

@main
struct CareerCompanionApp: App {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isDemoMode = AppSettings.shared.isDemoMode
    @State private var showDemoSheet = false
    @State private var showSetupView = false
    @State private var showSplash = true
    @State private var refreshID = UUID()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    AdaptiveRootView()
                        .id(refreshID)
                        .environmentObject(cloudKitManager)
                        .sheet(isPresented: $showDemoSheet) {
                            DemoModeSheet(onStartFresh: startFresh)
                        }
                        .sheet(isPresented: $showSetupView) {
                            SetupView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        }
                        .onAppear {
                            // Show demo sheet if just completed onboarding and in demo mode
                            if isDemoMode && AppSettings.shared.hasExploredDemo {
                                showDemoSheet = true
                            }
                        }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding, isDemoMode: $isDemoMode)
                        .environmentObject(cloudKitManager)
                        .onChange(of: hasCompletedOnboarding) { _, completed in
                            if completed && isDemoMode {
                                showDemoSheet = true
                            }
                        }
                }

                // Splash screen overlay
                if showSplash {
                    SplashScreenView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .demoModeBanner()
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                let newValue = AppSettings.shared.isDemoMode
                if newValue != isDemoMode {
                    isDemoMode = newValue
                    // Force complete view refresh to reload data
                    refreshID = UUID()
                }
            }
        }
    }

    private func startFresh() {
        AppSettings.shared.isDemoMode = false
        isDemoMode = false
        showDemoSheet = false
        showSetupView = true
    }
}

// MARK: - Adaptive Root View

/// Switches between TabView (iPhone) and Sidebar (iPad) based on device
struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadSidebarView()
        } else {
            MainTabView()
        }
    }
}

// MARK: - iPad Sidebar Navigation

struct iPadSidebarView: View {
    @State private var sidebarSelection: SidebarItem? = .home
    @State private var selectedMeeting: Meeting?
    @State private var selectedGoal: CareerGoal?
    @State private var selectedActionItem: ActionItem?

    enum SidebarItem: String, CaseIterable, Identifiable {
        case home = "Home"
        case meetings = "1:1s"
        case actionItems = "Action Items"
        case career = "Career"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .meetings: return "person.2.fill"
            case .actionItems: return "checklist"
            case .career: return "star.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar
            List(SidebarItem.allCases, selection: $sidebarSelection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Career Companion")
        } content: {
            // Content (list) pane
            switch sidebarSelection {
            case .home:
                HomeView()
            case .meetings:
                iPadMeetingsListView(selectedMeeting: $selectedMeeting)
            case .actionItems:
                iPadActionItemsListView(selectedActionItem: $selectedActionItem)
            case .career:
                iPadCareerView(selectedGoal: $selectedGoal)
            case .settings:
                SettingsView()
            case .none:
                ContentUnavailableView(
                    "Select a Section",
                    systemImage: "sidebar.left",
                    description: Text("Choose a section from the sidebar")
                )
            }
        } detail: {
            // Detail pane
            switch sidebarSelection {
            case .meetings:
                if let meeting = selectedMeeting {
                    MeetingDetailView(meeting: meeting)
                } else {
                    ContentUnavailableView(
                        "Select a Meeting",
                        systemImage: "person.2",
                        description: Text("Choose a meeting from the list")
                    )
                }
            case .actionItems:
                if let actionItem = selectedActionItem {
                    ActionItemDetailView(item: actionItem)
                } else {
                    ContentUnavailableView(
                        "Select an Action Item",
                        systemImage: "checklist",
                        description: Text("Choose an action item from the list")
                    )
                }
            case .career:
                if let goal = selectedGoal {
                    GoalDetailView(goal: goal)
                } else {
                    ContentUnavailableView(
                        "Select a Goal",
                        systemImage: "star",
                        description: Text("Choose a goal from the list")
                    )
                }
            default:
                ContentUnavailableView(
                    "No Detail View",
                    systemImage: "doc.text",
                    description: Text("Select an item to view details")
                )
            }
        }
        .tint(Colors.primary)
    }
}

// MARK: - iPad Meetings List (for split view)

struct iPadMeetingsListView: View {
    @StateObject private var viewModel = MeetingsViewModel()
    @Binding var selectedMeeting: Meeting?
    @State private var showingNewMeeting = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.allMeetings.isEmpty {
                ProgressView("Loading meetings...")
            } else if viewModel.allMeetings.isEmpty {
                VStack(spacing: Spacing.lg) {
                    EmptyState(
                        icon: "person.2",
                        title: "No 1:1 Meetings",
                        message: "Schedule your first 1:1 meeting to start tracking.",
                        actionTitle: "Schedule Meeting",
                        action: { showingNewMeeting = true }
                    )
                }
            } else {
                List(selection: $selectedMeeting) {
                    // Relationship type filter
                    Section {
                        Picker("Filter by", selection: $viewModel.relationshipFilter) {
                            ForEach(RelationshipFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Upcoming meetings
                    if !viewModel.upcomingMeetings.isEmpty {
                        Section("Upcoming") {
                            ForEach(viewModel.upcomingMeetings) { meeting in
                                MeetingRowView(
                                    meeting: meeting,
                                    managerName: viewModel.managerName(for: meeting.managerID)
                                )
                                .tag(meeting)
                            }
                        }
                    }

                    // Past meetings
                    if !viewModel.pastMeetings.isEmpty {
                        Section("Past") {
                            ForEach(viewModel.pastMeetings) { meeting in
                                MeetingRowView(
                                    meeting: meeting,
                                    managerName: viewModel.managerName(for: meeting.managerID)
                                )
                                .tag(meeting)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("1:1 Meetings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingNewMeeting = true }) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Schedule meeting")
                }
            }
        }
        .sheet(isPresented: $showingNewMeeting) {
            AddMeetingView(managers: viewModel.managers) { meeting in
                Task {
                    await viewModel.createMeeting(meeting)
                }
            }
        }
        .refreshable {
            await viewModel.loadMeetings()
        }
        .task {
            await viewModel.loadMeetings()
        }
    }
}

// MARK: - iPad Career View (for split view)

struct iPadCareerView: View {
    @Binding var selectedGoal: CareerGoal?
    @StateObject private var viewModel = CareerHomeViewModel()
    @State private var goalFilter: GoalFilter = .active

    var body: some View {
        List(selection: $selectedGoal) {
            // Filter picker
            Section {
                Picker("Filter", selection: $goalFilter) {
                    ForEach(GoalFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Goals list
            if filteredGoals.isEmpty {
                Section {
                    Text("No \(goalFilter.displayName.lowercased()) goals")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(filteredGoals) { goal in
                        GoalRowView(goal: goal)
                            .tag(goal)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Career Goals")
        .task {
            await viewModel.loadData()
        }
    }

    private var filteredGoals: [CareerGoal] {
        switch goalFilter {
        case .active:
            return viewModel.goals.filter { $0.status == .inProgress || $0.status == .notStarted }
        case .achieved:
            return viewModel.goals.filter { $0.status == .achieved }
        case .all:
            return viewModel.goals
        }
    }
}

// MARK: - iPad Action Items List (for split view)

struct iPadActionItemsListView: View {
    @StateObject private var viewModel = ActionItemsViewModel()
    @Binding var selectedActionItem: ActionItem?
    @State private var selectedFilter: ActionItemFilter = .open
    @State private var showingAddItem = false

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ActionItemFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // List
            if viewModel.filteredItems(for: selectedFilter).isEmpty {
                Spacer()
                EmptyState(
                    icon: selectedFilter == .overdue ? "clock.badge.checkmark" : "checklist",
                    title: selectedFilter == .overdue ? "Nothing Overdue" : "No Action Items",
                    message: selectedFilter == .overdue
                        ? "Great job staying on top of your tasks!"
                        : "Add action items from your 1:1 meetings."
                )
                Spacer()
            } else {
                List(selection: $selectedActionItem) {
                    ForEach(viewModel.filteredItems(for: selectedFilter)) { item in
                        ActionItemRowView(item: item)
                            .tag(item)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Action Items")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add action item")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddActionItemView { item in
                Task {
                    await viewModel.addItem(item)
                }
            }
        }
        .refreshable {
            await viewModel.loadItems()
        }
        .task {
            await viewModel.loadItems()
        }
    }
}

// MARK: - Action Item Row View (for iPad list)

private struct ActionItemRowView: View {
    let item: ActionItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Image(systemName: item.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.status == .completed ? Colors.success : (item.isOverdue ? Colors.error : Colors.textTertiary))
                .font(.title3)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.title)
                    .font(Typography.body)
                    .strikethrough(item.status == .completed)
                    .foregroundStyle(item.status == .completed ? Colors.textSecondary : Colors.textPrimary)

                HStack(spacing: Spacing.sm) {
                    if item.priority == .high {
                        Label("High", systemImage: item.priority.icon)
                            .foregroundStyle(item.priority.color)
                    }

                    if let date = item.formattedDueDate {
                        Label(date, systemImage: "calendar")
                            .foregroundStyle(item.isOverdue ? Colors.error : Colors.textSecondary)
                    }

                    Label(item.owner.displayName, systemImage: item.owner.icon)
                        .foregroundStyle(Colors.textSecondary)
                }
                .font(Typography.caption1)
                .labelStyle(CompactLabelStyle())
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Goal Row View (for iPad list)

private struct GoalRowView: View {
    let goal: CareerGoal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(goal.title)
                .font(Typography.headline)
                .foregroundStyle(Colors.textPrimary)

            HStack {
                Label(goal.category.displayName, systemImage: goal.category.icon)
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)

                Spacer()

                Text("\(Int(goal.progress))%")
                    .font(Typography.caption1)
                    .foregroundStyle(goal.status.color)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home
        case meetings
        case career
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            NavigationStack {
                MeetingsListView()
            }
            .tabItem {
                Label("1:1s", systemImage: "person.2.fill")
            }
            .tag(Tab.meetings)

            NavigationStack {
                CareerHomeView()
            }
            .tabItem {
                Label("Career", systemImage: "star.fill")
            }
            .tag(Tab.career)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .tint(Colors.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(CloudKitManager.shared)
}
