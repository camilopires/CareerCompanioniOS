import Foundation
import WatchConnectivity

/// Manages WatchConnectivity session for syncing meeting data with Apple Watch
@MainActor
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isReachable = false
    private var session: WCSession?

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported on this device")
            return
        }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Data to Watch

    /// Send active meeting data to Watch
    func sendActiveMeeting(_ meeting: Meeting?, managerName: String, actionItems: [ActionItem]) {
        guard let session, session.activationState == .activated else {
            print("Watch session not activated")
            return
        }

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

        // Use transferUserInfo for background delivery, sendMessage for immediate
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("Failed to send message to Watch: \(error)")
            }
        } else {
            // Queue for when Watch becomes reachable
            session.transferUserInfo(data)
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
            print("Unknown message type from Watch: \(type)")
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
            print("Failed to complete meeting from Watch: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("Watch session activated: \(activationState.rawValue), reachable: \(session.isReachable)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("Watch reachability changed: \(session.isReachable)")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleWatchMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleWatchMessage(message)
            replyHandler(["status": "received"])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let meetingCompletedFromWatch = Notification.Name("meetingCompletedFromWatch")
}
