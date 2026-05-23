import Foundation
import os

/// Ends listening when the user stays silent — avoids stuck “listening” with no transcript.
@MainActor
final class NoSpeechTimeoutMonitor {
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "NoSpeech")

    private let timeoutDuration: TimeInterval = 4.0
    private let minimumSpeechCharacters = 3
    private let pollInterval: TimeInterval = 0.15

    private var monitorTask: Task<Void, Never>?
    private var listeningStartDate: Date?
    private var onTimeout: (() -> Void)?
    private var hasTriggered = false
    private(set) var isMonitoring = false

    func start(
        transcriptProvider: @escaping () -> String,
        isListeningProvider: @escaping () -> Bool,
        onTimeout: @escaping () -> Void
    ) {
        stop()

        self.onTimeout = onTimeout
        listeningStartDate = Date()
        hasTriggered = false
        isMonitoring = true

        logger.info("No-speech monitor started.")

        monitorTask = Task { @MainActor in
            while !Task.isCancelled {
                guard isListeningProvider() else {
                    try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    continue
                }

                let transcript = normalize(transcriptProvider())
                if transcript.count >= minimumSpeechCharacters {
                    logger.debug("No-speech monitor cancelled — speech detected.")
                    stop()
                    return
                }

                if let start = listeningStartDate,
                   Date().timeIntervalSince(start) >= timeoutDuration,
                   !hasTriggered {
                    hasTriggered = true
                    isMonitoring = false
                    monitorTask?.cancel()
                    monitorTask = nil
                    logger.info("No-speech timeout triggered after \(self.timeoutDuration, privacy: .public)s.")
                    onTimeout()
                    return
                }

                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
        listeningStartDate = nil
        onTimeout = nil
        hasTriggered = false
        logger.debug("No-speech monitor stopped.")
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
