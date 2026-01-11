import Foundation
import WatchConnectivity

/// Watch-side WatchConnectivity session manager
@MainActor
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var hasActiveMeeting = false
    @Published var activeMeeting: WatchMeetingData?
    @Published var isReachable = false

    private var session: WCSession?

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported")
            return
        }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Commands to iPhone

    /// Request iPhone to complete the active meeting
    func completeMeeting(_ meetingID: UUID) {
        guard let session, session.activationState == .activated else {
            print("Session not activated")
            return
        }

        let message: [String: Any] = [
            "type": "completeMeeting",
            "meetingID": meetingID.uuidString
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: { _ in
                // Success
            }) { error in
                print("Failed to send complete meeting: \(error)")
            }
        }

        // Optimistically update local state
        hasActiveMeeting = false
        activeMeeting = nil
    }

    // MARK: - Handle iPhone Messages

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "activeMeeting":
            let hasActive = message["hasActiveMeeting"] as? Bool ?? false
            hasActiveMeeting = hasActive

            if hasActive {
                activeMeeting = WatchMeetingData(from: message)
            } else {
                activeMeeting = nil
            }

        default:
            print("Unknown message type: \(type)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("Watch session activated: \(activationState.rawValue)")
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleMessage(message)
            replyHandler(["status": "received"])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.handleMessage(userInfo)
        }
    }
}

// MARK: - Watch Data Models

struct WatchMeetingData: Identifiable {
    let id: UUID
    let managerName: String
    let date: Date
    let agenda: [String]
    let blockers: [String]
    let actionItems: [WatchActionItem]

    init?(from message: [String: Any]) {
        guard let meetingIDString = message["meetingID"] as? String,
              let meetingID = UUID(uuidString: meetingIDString),
              !meetingIDString.isEmpty else {
            return nil
        }

        self.id = meetingID
        self.managerName = message["managerName"] as? String ?? "Manager"
        self.date = Date(timeIntervalSince1970: message["date"] as? TimeInterval ?? 0)
        self.agenda = message["agenda"] as? [String] ?? []
        self.blockers = message["blockers"] as? [String] ?? []

        // Parse action items
        if let itemsData = message["actionItems"] as? [[String: Any]] {
            self.actionItems = itemsData.compactMap { WatchActionItem(from: $0) }
        } else {
            self.actionItems = []
        }
    }
}

struct WatchActionItem: Identifiable {
    let id: UUID
    let title: String
    let completed: Bool

    init?(from dict: [String: Any]) {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = dict["title"] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.completed = dict["completed"] as? Bool ?? false
    }
}
