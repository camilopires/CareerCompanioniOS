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
    private var pollingTimer: Timer?

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Polling

    /// Start periodic polling (only when there's an active meeting)
    func startPollingIfNeeded() {
        guard hasActiveMeeting else { return }
        guard pollingTimer == nil else { return }
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.requestMeetingStatus()
            }
        }
    }

    /// Stop polling
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    /// Request current meeting status from iPhone
    func requestMeetingStatus() {
        guard let session, session.activationState == .activated else { return }
        guard session.isReachable else { return }

        let request: [String: Any] = ["type": "requestMeetingStatus"]

        session.sendMessage(request, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleMessage(reply)
            }
        }) { _ in }
    }

    // MARK: - Send Commands to iPhone

    /// Request iPhone to complete the active meeting
    func completeMeeting(_ meetingID: UUID) {
        guard let session, session.activationState == .activated else { return }

        let message: [String: Any] = [
            "type": "completeMeeting",
            "meetingID": meetingID.uuidString
        ]

        if session.isReachable {
            session.sendMessage(message, replyHandler: { _ in }) { _ in }
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
                if let meetingData = WatchMeetingData(from: message) {
                    activeMeeting = meetingData
                    startPollingIfNeeded()
                } else {
                    activeMeeting = nil
                    stopPolling()
                }
            } else {
                activeMeeting = nil
                stopPolling()
            }

        default:
            break
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            // Check for existing application context
            let context = session.receivedApplicationContext
            if !context.isEmpty {
                self.handleMessage(context)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            let wasReachable = self.isReachable
            self.isReachable = session.isReachable

            // Poll for meeting status when iPhone becomes reachable
            if session.isReachable && !wasReachable {
                self.requestMeetingStatus()
            }
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

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handleMessage(applicationContext)
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
