import SwiftUI
import CloudKit

@main
struct OneToOneTrackerApp: App {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(cloudKitManager)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(cloudKitManager)
            }
        }
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
