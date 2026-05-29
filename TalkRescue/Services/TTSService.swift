import AVFoundation
import Foundation
import os

@MainActor
final class TTSService: NSObject {
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "TTS")
    private let synthesizer = AVSpeechSynthesizer()
    private var preparedVoice: AVSpeechSynthesisVoice?
    private var voiceLanguage = LanguageProfile.default.ttsVoiceLanguage
    /// Slightly slower than default — clearer for stressed users and Auto Speak.
    private let speechRate = AVSpeechUtteranceDefaultSpeechRate * 0.94

    var onSpeakingChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func prepare(voiceLanguage: String = LanguageProfile.default.ttsVoiceLanguage) {
        self.voiceLanguage = voiceLanguage
        preparedVoice = Self.resolveBestVoice(for: voiceLanguage)
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

    /// Stops speech and releases playback so the mic session can take over cleanly.
    func releasePlaybackForRecording() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            onSpeakingChanged?(false)
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.debug("Playback release skipped: \(error.localizedDescription, privacy: .public)")
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
        let voice = preparedVoice ?? Self.resolveBestVoice(for: voiceLanguage)
        utterance.voice = voice
        utterance.rate = min(speechRate, AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.12
        utterance.preUtteranceDelay = 0.05
        synthesizer.speak(utterance)
        onSpeakingChanged?(true)
        logger.info("TTS start length=\(trimmedText.count, privacy: .public) voice=\(voice?.name ?? "default", privacy: .public)")
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        onSpeakingChanged?(false)
        logger.debug("Stopped TTS playback.")
    }
}

private extension TTSService {
    static func resolveBestVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let exactMatches = allVoices.filter { $0.language == languageCode }
        let baseCode = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        let regionalMatches = exactMatches.isEmpty
            ? allVoices.filter { $0.language.hasPrefix(baseCode) }
            : exactMatches

        let pool = regionalMatches.isEmpty ? allVoices.filter { $0.language.hasPrefix(baseCode) } : regionalMatches

        if let enhanced = pool.filter({ $0.quality == .enhanced }).max(by: voiceSort) {
            return enhanced
        }
        if #available(iOS 16.0, *), let premium = pool.filter({ $0.quality == .premium }).max(by: voiceSort) {
            return premium
        }
        if let preferred = preferredNamedVoice(in: pool, languageCode: languageCode) {
            return preferred
        }
        return AVSpeechSynthesisVoice(language: languageCode)
            ?? AVSpeechSynthesisVoice(language: baseCode)
    }

    /// Known high-quality voices when enhanced tier is unavailable on device.
    static func preferredNamedVoice(in pool: [AVSpeechSynthesisVoice], languageCode: String) -> AVSpeechSynthesisVoice? {
        let names: [String]
        switch languageCode {
        case "en-US", "en-GB":
            names = ["Samantha", "Alex", "Daniel"]
        case "sv-SE":
            names = ["Alva", "Oskar"]
        case "es-ES":
            names = ["Mónica", "Monica", "Jorge"]
        default:
            names = []
        }
        for name in names {
            if let match = pool.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) {
                return match
            }
        }
        return pool.max(by: voiceSort)
    }

    static func voiceSort(_ lhs: AVSpeechSynthesisVoice, _ rhs: AVSpeechSynthesisVoice) -> Bool {
        lhs.name < rhs.name
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
