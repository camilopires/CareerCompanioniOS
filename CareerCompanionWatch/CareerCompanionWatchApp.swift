import SwiftUI

@main
struct CareerCompanionWatchApp: App {

    init() {
        // Initialize WatchConnectivity session on main actor
        Task { @MainActor in
            WatchSessionManager.shared.startSession()
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
