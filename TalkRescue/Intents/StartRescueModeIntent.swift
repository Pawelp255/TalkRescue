import AppIntents
import os

/// Opens TalkRescue directly into Rescue Mode with the mic ready.
struct StartRescueModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Rescue Mode"
    static let description = IntentDescription("Open TalkRescue and start listening immediately.")
    static let openAppWhenRun = true

    private static let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Intent")

    @MainActor
    func perform() async throws -> some IntentResult {
        Self.logger.info("Start Rescue Mode intent performed.")
        RescueLaunchCoordinator.shared.requestRescueMode(source: .shortcut, autoListen: true)
        return .result()
    }
}
