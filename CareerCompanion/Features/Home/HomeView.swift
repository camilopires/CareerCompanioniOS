import SwiftUI

/// Main home screen with mode-aware dashboard
/// Displays ICDashboardView for Individual Contributors
/// Displays ManagerDashboardView for Managers
struct HomeView: View {
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
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
