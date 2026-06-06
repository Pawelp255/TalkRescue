import Foundation
import os

/// Central launch routing for Rescue Mode (shortcuts, Action Button, in-app).
/// Persists pending launch to survive cold-start race with AppIntent.
@MainActor
final class RescueLaunchCoordinator: ObservableObject {
    static let shared = RescueLaunchCoordinator()

    private static let pendingLaunchKey = "talkRescue.pendingRescueLaunch"
    private static let autoListenKey = "talkRescue.rescueAutoListen"
    private static let pendingRequestIDKey = "talkRescue.pendingRescueRequestID"

    enum LaunchSource: String {
        case shortcut
        case inApp
    }

    @Published var showRescueMode = false
    @Published private(set) var shouldAutoStartListening = false
    @Published private(set) var lastLaunchSource: LaunchSource?
    @Published private(set) var autoListenInProgress = false
    @Published private(set) var launchedDirectlyToRescue = false
    /// Increments on every shortcut/Action Button/in-app rescue request.
    @Published private(set) var rescueRequestID: UInt = 0
    /// Last request ID that completed an auto-listen attempt (success or failure).
    @Published private(set) var lastAutoListenHandledRequestID: UInt = 0

    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Launch")

    private init() {
        restorePendingLaunchFromStorage()
    }

    func requestRescueMode(source: LaunchSource, autoListen: Bool = true) {
        rescueRequestID += 1
        autoListenInProgress = false
        shouldAutoStartListening = autoListen
        launchedDirectlyToRescue = source == .shortcut && !showRescueMode
        showRescueMode = true
        lastLaunchSource = source
        LocalUsageAnalytics.recordRescueModeUse()
        if source == .shortcut {
            LocalUsageAnalytics.recordShortcutRescueLaunch()
        }
        persistPendingLaunch(autoListen: autoListen, requestID: rescueRequestID)
        logger.info("New rescue request id=\(self.rescueRequestID, privacy: .public) source=\(source.rawValue, privacy: .public) autoListen=\(autoListen, privacy: .public)")
    }

    func restorePendingLaunchIfNeeded() {
        restorePendingLaunchFromStorage()
    }

    /// Whether this request still needs auto-listen.
    func shouldAutoListen(for requestID: UInt) -> Bool {
        guard requestID > 0, requestID > lastAutoListenHandledRequestID else { return false }
        return shouldAutoStartListening
    }

    func beginAutoListenAttempt(requestID: UInt, force: Bool = false) -> Bool {
        if force {
            autoListenInProgress = false
        }
        guard !autoListenInProgress else {
            logger.info("Auto-start skipped — already in progress requestId=\(requestID, privacy: .public)")
            return false
        }
        guard force || shouldAutoListen(for: requestID) else {
            logger.info("Request ignored — already handled requestId=\(requestID, privacy: .public)")
            return false
        }
        autoListenInProgress = true
        logger.info("Auto-start requested requestId=\(requestID, privacy: .public) force=\(force, privacy: .public)")
        return true
    }

    func finishAutoListenAttempt(requestID: UInt) {
        autoListenInProgress = false
        shouldAutoStartListening = false
        if requestID > lastAutoListenHandledRequestID {
            lastAutoListenHandledRequestID = requestID
        }
        logger.info("Auto-listen finished for requestId=\(requestID, privacy: .public)")
    }

    func markAutoListenHandled(for requestID: UInt) {
        finishAutoListenAttempt(requestID: requestID)
    }

    func dismissRescueMode() {
        showRescueMode = false
        shouldAutoStartListening = false
        launchedDirectlyToRescue = false
        autoListenInProgress = false
        clearPersistedLaunch()
    }

    func logRescuePresentationIfNeeded() {
        guard launchedDirectlyToRescue else { return }
        LaunchMetrics.log("Launch-to-rescue-UI", since: LaunchMetrics.coldStartTime)
    }

    private func restorePendingLaunchFromStorage() {
        guard UserDefaults.standard.bool(forKey: Self.pendingLaunchKey) else { return }

        let autoListen = UserDefaults.standard.object(forKey: Self.autoListenKey) as? Bool ?? true
        let storedRequestID = UInt(UserDefaults.standard.integer(forKey: Self.pendingRequestIDKey))
        clearPersistedLaunch()

        if storedRequestID > rescueRequestID {
            rescueRequestID = storedRequestID
        } else if storedRequestID == 0 {
            rescueRequestID += 1
        }

        autoListenInProgress = false
        shouldAutoStartListening = autoListen
        launchedDirectlyToRescue = true
        showRescueMode = true
        lastLaunchSource = .shortcut
        LaunchMetrics.logSinceLaunch("Cold-start rescue restore")
        logger.info("Restored persisted rescue request id=\(self.rescueRequestID, privacy: .public) autoListen=\(autoListen, privacy: .public)")
    }

    private func persistPendingLaunch(autoListen: Bool, requestID: UInt) {
        UserDefaults.standard.set(true, forKey: Self.pendingLaunchKey)
        UserDefaults.standard.set(autoListen, forKey: Self.autoListenKey)
        UserDefaults.standard.set(Int(requestID), forKey: Self.pendingRequestIDKey)
    }

    private func clearPersistedLaunch() {
        UserDefaults.standard.removeObject(forKey: Self.pendingLaunchKey)
        UserDefaults.standard.removeObject(forKey: Self.autoListenKey)
        UserDefaults.standard.removeObject(forKey: Self.pendingRequestIDKey)
    }
}
