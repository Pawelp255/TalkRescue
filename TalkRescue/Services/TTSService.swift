import AVFoundation
import Foundation
import os

@MainActor
final class TTSService: NSObject {
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "TTS")
    private let synthesizer = AVSpeechSynthesizer()
    private var preparedVoice: AVSpeechSynthesisVoice?
    private var voiceLanguage = LanguageProfile.default.ttsVoiceLanguage
    /// Slightly faster than default for rescue conversations.
    private let rescueRate = AVSpeechUtteranceDefaultSpeechRate * 1.12

    var onSpeakingChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func prepare(voiceLanguage: String = LanguageProfile.default.ttsVoiceLanguage) {
        self.voiceLanguage = voiceLanguage
        preparedVoice = Self.resolveVoice(for: voiceLanguage)
    }

    /// Activates playback session early so first Auto Speak starts faster.
    func warmPlaybackSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.debug("Playback warm-up skipped: \(error.localizedDescription, privacy: .public)")
        }
    }

    func speak(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        warmPlaybackSession()

        let utterance = AVSpeechUtterance(string: trimmedText)
        utterance.voice = preparedVoice ?? Self.resolveVoice(for: voiceLanguage)
        utterance.rate = min(rescueRate, AVSpeechUtteranceMaximumSpeechRate)
        synthesizer.speak(utterance)
        onSpeakingChanged?(true)
        logger.info("TTS start length=\(trimmedText.count, privacy: .public)")
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        onSpeakingChanged?(false)
        logger.debug("Stopped TTS playback.")
    }
}

private extension TTSService {
    static func resolveVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            return voice
        }
        let base = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return AVSpeechSynthesisVoice(language: base)
    }
}

extension TTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onSpeakingChanged?(false)
            logger.debug("TTS finished.")
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onSpeakingChanged?(false)
            logger.debug("TTS cancelled.")
        }
    }
}
