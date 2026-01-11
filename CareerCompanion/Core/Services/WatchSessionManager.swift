import Foundation
import WatchConnectivity

/// Manages WatchConnectivity session for syncing meeting data with Apple Watch
@MainActor
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isReachable = false
    private var session: WCSession?
    private var currentMeetingData: [String: Any]?

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Data to Watch

    /// Send active meeting data to Watch
    func sendActiveMeeting(_ meeting: Meeting?, managerName: String, actionItems: [ActionItem]) {
        guard let session else { return }
        guard session.activationState == .activated else { return }

        let data: [String: Any] = [
            "type": "activeMeeting",
            "hasActiveMeeting": meeting != nil,
            "meetingID": meeting?.id.uuidString ?? "",
            "managerName": managerName,
            "date": meeting?.date.timeIntervalSince1970 ?? 0,
            "agenda": meeting?.thisWeekGoals ?? [],
            "blockers": meeting?.blockers ?? [],
            "actionItems": actionItems.map { item in
                [
                    "id": item.id.uuidString,
                    "title": item.title,
                    "completed": item.status == .completed
                ] as [String: Any]
            }
        ]

        // Store for re-sending on reachability change and polling
        currentMeetingData = data

        // Use applicationContext for state sync (survives app restarts)
        try? session.updateApplicationContext(data)

        // Also use transferUserInfo as backup
        session.transferUserInfo(data)

        // Also try sendMessage if reachable for immediate delivery
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { _ in }
        }
    }

    /// Clear active meeting on Watch
    func clearActiveMeeting() {
        sendActiveMeeting(nil, managerName: "", actionItems: [])
    }

    // MARK: - Handle Watch Commands

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "completeMeeting":
            if let meetingIDString = message["meetingID"] as? String,
               let meetingID = UUID(uuidString: meetingIDString) {
                Task {
                    await completeMeetingFromWatch(meetingID: meetingID)
                }
            }
        default:
            break
        }
    }

    private func completeMeetingFromWatch(meetingID: UUID) async {
        guard !AppSettings.shared.isDemoMode else {
            // In demo mode, just clear the Watch
            clearActiveMeeting()
            return
        }

        do {
            if let sdMeeting = try DataManager.shared.fetchMeeting(by: meetingID) {
                sdMeeting.status = .completed
                sdMeeting.updatedAt = Date()
                try DataManager.shared.save()

                // Clear Watch
                clearActiveMeeting()

                // Post notification so UI can update
                NotificationCenter.default.post(name: .meetingCompletedFromWatch, object: meetingID)
            }
        } catch {
            // Silent failure
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            // Re-send current meeting data when Watch becomes reachable
            if session.isReachable, let data = self.currentMeetingData {
                session.sendMessage(data, replyHandler: nil) { _ in }
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleWatchMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            // Handle polling request from Watch
            if message["type"] as? String == "requestMeetingStatus" {
                let responseData: [String: Any]
                if let data = self.currentMeetingData {
                    responseData = data
                } else {
                    responseData = ["type": "activeMeeting", "hasActiveMeeting": false]
                }
                replyHandler(responseData)

                // Also send via sendMessage as backup
                if session.isReachable {
                    session.sendMessage(responseData, replyHandler: nil) { _ in }
                }
                return
            }

            self.handleWatchMessage(message)
            replyHandler(["status": "received"])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let meetingCompletedFromWatch = Notification.Name("meetingCompletedFromWatch")
}
