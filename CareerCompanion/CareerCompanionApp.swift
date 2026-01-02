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

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                MainTabView()
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
        }
    }

    private func startFresh() {
        AppSettings.shared.isDemoMode = false
        isDemoMode = false
        showDemoSheet = false
        showSetupView = true
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home
        case meetings
        case career
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            MeetingsListView()
                .tabItem {
                    Label("1:1s", systemImage: "person.2.fill")
                }
                .tag(Tab.meetings)

            CareerHomeView()
                .tabItem {
                    Label("Career", systemImage: "star.fill")
                }
                .tag(Tab.career)
        }
        .tint(Colors.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(CloudKitManager.shared)
}
