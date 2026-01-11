import SwiftUI

@main
struct CareerCompanionWatchApp: App {

    init() {
        // Initialize WatchConnectivity session
        WatchSessionManager.shared.startSession()
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
