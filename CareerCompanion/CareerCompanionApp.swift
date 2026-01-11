import SwiftUI
import SwiftData

@main
struct CareerCompanionApp: App {
    @StateObject private var dataManager = DataManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isDemoMode = AppSettings.shared.isDemoMode
    @State private var showDemoSheet = false
    @State private var showSetupView = false
    @State private var showSplash = true
    @State private var refreshID = UUID()

    init() {
        // Initialize WatchConnectivity session
        WatchSessionManager.shared.startSession()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    AdaptiveRootView()
                        .id(refreshID)
                        .modelContainer(dataManager.container)
                        .sheet(isPresented: $showDemoSheet) {
                            DemoModeSheet(onStartFresh: startFresh)
                        }
                        .sheet(isPresented: $showSetupView) {
                            SetupView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        }
                        .onChange(of: showSplash) { _, isSplashVisible in
                            // Show demo sheet after splash dismisses (not during)
                            if !isSplashVisible && isDemoMode && AppSettings.shared.hasExploredDemo {
                                showDemoSheet = true
                            }
                        }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding, isDemoMode: $isDemoMode)
                        .modelContainer(dataManager.container)
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

    enum SidebarItem: String, CaseIterable, Identifiable {
        case home = "Home"
        case meetings = "1:1s"
        case career = "Career"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .meetings: return "person.2.fill"
            case .career: return "star.fill"
            case .settings: return "gearshape.fill"
            }
        }

        /// Whether this tab uses a full-screen layout (no detail pane)
        var usesFullScreenLayout: Bool {
            switch self {
            case .home, .settings:
                return true
            case .meetings, .career:
                return false
            }
        }
    }

    var body: some View {
        Group {
            if sidebarSelection?.usesFullScreenLayout == true {
                // Two-column layout for Home and Settings (full-screen content)
                NavigationSplitView {
                    sidebarContent
                } detail: {
                    fullScreenContent
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // Three-column layout for tabs with detail views
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    sidebarContent
                } content: {
                    listContent
                } detail: {
                    detailContent
                }
            }
        }
        .tint(Colors.primary)
    }

    // MARK: - Sidebar Content

    private var sidebarContent: some View {
        List(SidebarItem.allCases, selection: $sidebarSelection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .navigationTitle("Career Companion")
    }

    // MARK: - Full Screen Content (for Home and Settings)

    @ViewBuilder
    private var fullScreenContent: some View {
        switch sidebarSelection {
        case .home:
            HomeView()
        case .settings:
            SettingsView()
        default:
            EmptyView()
        }
    }

    // MARK: - List Content (for three-column layout)

    @ViewBuilder
    private var listContent: some View {
        switch sidebarSelection {
        case .meetings:
            iPadMeetingsListView(selectedMeeting: $selectedMeeting)
        case .career:
            iPadCareerView(selectedGoal: $selectedGoal)
        case .home, .settings, .none:
            ContentUnavailableView(
                "Select a Section",
                systemImage: "sidebar.left",
                description: Text("Choose a section from the sidebar")
            )
        }
    }

    // MARK: - Detail Content (for three-column layout)

    @ViewBuilder
    private var detailContent: some View {
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
                                .listRowBackground(
                                    selectedMeeting == meeting
                                        ? Colors.primaryLight
                                        : Color.clear
                                )
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
                                .listRowBackground(
                                    selectedMeeting == meeting
                                        ? Colors.primaryLight
                                        : Color.clear
                                )
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
                            .listRowBackground(
                                selectedGoal == goal
                                    ? Colors.primaryLight
                                    : Color.clear
                            )
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
        .modelContainer(DataManager.shared.container)
}
