import SwiftUI

/// Main home screen with mode-aware dashboard
/// Displays ICDashboardView for Individual Contributors
/// Displays ManagerDashboardView for Managers
struct HomeView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager

    private var userRole: UserRole { AppSettings.shared.userRole }

    var body: some View {
        NavigationStack {
            Group {
                if userRole == .manager {
                    ManagerDashboardView()
                } else {
                    ICDashboardView()
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(CloudKitManager.shared)
}
