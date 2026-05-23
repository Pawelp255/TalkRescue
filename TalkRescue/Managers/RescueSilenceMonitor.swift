import Foundation
import os

/// Conservative transcript-based silence detection for Rescue Mode only.
@MainActor
final class RescueSilenceMonitor {
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Silence")

    private let silenceDuration: TimeInterval = 1.35
    private let shortTranscriptSilenceDuration: TimeInterval = 1.8
    private let minimumRecordingAfterSpeech: TimeInterval = 0.8
    private let minimumSpeechCharacters = 3
    private let pollInterval: TimeInterval = 0.12

    private var monitorTask: Task<Void, Never>?
    private var onAutoFinish: (() -> Void)?
    private var onSpeechDetected: ((Bool) -> Void)?

    private var lastTranscript = ""
    private var lastChangeDate: Date?
    private var speechStartDate: Date?
    private var speechStarted = false
    private var hasTriggeredFinish = false
    private(set) var isMonitoring = false

    func start(
        transcriptProvider: @escaping () -> String,
        isRecordingProvider: @escaping () -> Bool,
        onSpeechDetected: @escaping (Bool) -> Void,
        onAutoFinish: @escaping () -> Void
    ) {
        stop()

        self.onAutoFinish = onAutoFinish
        self.onSpeechDetected = onSpeechDetected
        lastTranscript = ""
        lastChangeDate = nil
        speechStartDate = nil
        speechStarted = false
        hasTriggeredFinish = false
        isMonitoring = true

        logger.info("Silence monitor started.")

        monitorTask = Task { @MainActor in
            while !Task.isCancelled {
                guard isRecordingProvider() else {
                    try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    continue
                }

                evaluate(transcript: transcriptProvider())
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
        onSpeechDetected?(false)
        onAutoFinish = nil
        onSpeechDetected = nil
        logger.debug("Silence monitor stopped.")
    }

    private func evaluate(transcript: String) {
        let trimmed = normalize(transcript)
        let now = Date()

        if !speechStarted, trimmed.count >= minimumSpeechCharacters {
            speechStarted = true
            lastChangeDate = now
            speechStartDate = now
            lastTranscript = trimmed
            onSpeechDetected?(true)
            logger.info("Speech started length=\(trimmed.count, privacy: .public)")
            return
        }

        guard speechStarted else {
            onSpeechDetected?(false)
            return
        }

        if isMeaningfulChange(from: lastTranscript, to: trimmed) {
            lastTranscript = trimmed
            lastChangeDate = now
            onSpeechDetected?(true)
            logger.debug("Silence timer reset transcriptLength=\(trimmed.count, privacy: .public)")
            return
        }

        if trimmed != lastTranscript, !trimmed.isEmpty, lastTranscript.hasPrefix(trimmed) || trimmed.hasPrefix(lastTranscript) {
            logger.debug("Noise/silence reset ignored transcriptLength=\(trimmed.count, privacy: .public)")
            return
        }

        guard trimmed.count >= minimumSpeechCharacters else { return }
        guard !hasTriggeredFinish else { return }
        guard let lastChangeDate else { return }
        if let speechStartDate, now.timeIntervalSince(speechStartDate) < minimumRecordingAfterSpeech {
            return
        }

        let elapsed = now.timeIntervalSince(lastChangeDate)
        let requiredSilence = trimmed.count < 6 ? shortTranscriptSilenceDuration : silenceDuration
        guard elapsed >= requiredSilence else { return }

        hasTriggeredFinish = true
        isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
        logger.info("Silence auto-finish triggered after \(elapsed, privacy: .public)s stable.")
        onAutoFinish?()
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Ignore tiny noisy flickers that should not reset the silence timer.
    private func isMeaningfulChange(from old: String, to new: String) -> Bool {
        if old == new { return false }
        if new.isEmpty { return old != new }

        let lengthDelta = abs(old.count - new.count)
        if lengthDelta <= 1, (old.hasPrefix(new) || new.hasPrefix(old)) {
            return false
        }

        let oldWords = old.split(separator: " ")
        let newWords = new.split(separator: " ")
        if oldWords.count == newWords.count,
           zip(oldWords, newWords).allSatisfy({ $0.0 == $0.1 || abs($0.0.count - $0.1.count) <= 1 }) {
            return false
        }

        return true
    }
}
