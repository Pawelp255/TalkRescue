import AVFoundation
import Foundation
import os

enum VoicePlaybackStyle: String, CaseIterable, Identifiable {
    case standard
    case natural

    var id: String { rawValue }

    static let userDefaultsKey = "voicePlaybackStyle"

    static var current: VoicePlaybackStyle {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let style = VoicePlaybackStyle(rawValue: raw) else {
            return .natural
        }
        return style
    }

    var speechRate: Float {
        switch self {
        case .standard:
            return AVSpeechUtteranceDefaultSpeechRate * 0.94
        case .natural:
            return AVSpeechUtteranceDefaultSpeechRate * 0.88
        }
    }

    var postUtteranceDelay: TimeInterval {
        switch self {
        case .standard: return 0.12
        case .natural: return 0.18
        }
    }

    var preUtteranceDelay: TimeInterval {
        switch self {
        case .standard: return 0.05
        case .natural: return 0.06
        }
    }
}

enum VoiceQualityTier: String {
    case premium
    case enhanced
    case compact
    case unknown

    var isHighQuality: Bool {
        self == .premium || self == .enhanced
    }
}

@MainActor
final class TTSService: NSObject {
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "TTS")
    private let synthesizer = AVSpeechSynthesizer()
    private var preparedVoice: AVSpeechSynthesisVoice?
    private var voiceLanguage = LanguageProfile.default.ttsVoiceLanguage
    private var voicesObserver: NSObjectProtocol?

    var onSpeakingChanged: ((Bool) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
        voicesObserver = NotificationCenter.default.addObserver(
            forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAvailableVoicesDidChange()
            }
        }
    }

    deinit {
        if let voicesObserver {
            NotificationCenter.default.removeObserver(voicesObserver)
        }
    }

    func prepare(voiceLanguage: String = LanguageProfile.default.ttsVoiceLanguage) {
        self.voiceLanguage = voiceLanguage
        refreshPreparedVoice()
    }

    func refreshPreparedVoice() {
        preparedVoice = Self.resolveBestVoice(for: voiceLanguage)
        if let voice = preparedVoice {
            logger.info(
                "Voice prepared lang=\(self.voiceLanguage, privacy: .public) name=\(voice.name, privacy: .public) tier=\(Self.tier(for: voice).rawValue, privacy: .public)"
            )
        }
    }

    private func handleAvailableVoicesDidChange() {
        logger.info("Available voices changed — refreshing prepared voice.")
        refreshPreparedVoice()
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

        let style = VoicePlaybackStyle.current
        let utterance = AVSpeechUtterance(string: trimmedText)
        let voice = preparedVoice ?? Self.resolveBestVoice(for: voiceLanguage)
        utterance.voice = voice
        utterance.rate = min(style.speechRate, AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = style.postUtteranceDelay
        utterance.preUtteranceDelay = style.preUtteranceDelay
        synthesizer.speak(utterance)
        onSpeakingChanged?(true)

        let tier = voice.map { Self.tier(for: $0) } ?? .unknown
        logger.info(
            "TTS start length=\(trimmedText.count, privacy: .public) voice=\(voice?.name ?? "default", privacy: .public) tier=\(tier.rawValue, privacy: .public) style=\(style.rawValue, privacy: .public)"
        )
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        onSpeakingChanged?(false)
        logger.debug("Stopped TTS playback.")
    }

    // MARK: - Voice inspection (About / diagnostics)

    static func resolvedVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        resolveBestVoice(for: languageCode)
    }

    static func resolvedTier(for languageCode: String) -> VoiceQualityTier {
        guard let voice = resolveBestVoice(for: languageCode) else { return .unknown }
        return tier(for: voice)
    }

    static func hasEnhancedVoice(for languageCode: String) -> Bool {
        voicePool(for: languageCode).contains { tier(for: $0).isHighQuality }
    }

    static func shouldSuggestEnhancedVoiceDownload(for languageCode: String) -> Bool {
        !hasEnhancedVoice(for: languageCode)
    }
}

// MARK: - Voice selection

private extension TTSService {
    static let voiceIdentifierChains: [String: [String]] = [
        "en-US": [
            "com.apple.voice.enhanced.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Joelle",
            "com.apple.voice.enhanced.en-US.Allison",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.speech.voice.Alex",
            "com.apple.voice.super-compact.en-US.Samantha",
        ],
        "de-DE": [
            "com.apple.ttsbundle.siri_female_de-DE_premium",
            "com.apple.ttsbundle.siri_male_de-DE_premium",
            "com.apple.ttsbundle.Anna-premium",
            "com.apple.voice.super-compact.de-DE.Anna",
        ],
        "sv-SE": [
            "com.apple.voice.enhanced.sv-SE.Alva",
            "com.apple.voice.enhanced.sv-SE.Oskar",
            "com.apple.voice.super-compact.sv-SE.Alva",
        ],
        "es-ES": [
            "com.apple.voice.enhanced.es-ES.Monica",
            "com.apple.voice.enhanced.es-ES.Mónica",
            "com.apple.voice.enhanced.es-ES.Jorge",
            "com.apple.voice.super-compact.es-ES.Monica",
        ],
    ]

    static func resolveBestVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let pool = voicePool(for: languageCode)

        if let chain = voiceIdentifierChains[languageCode] {
            for identifier in chain {
                if let match = voiceMatching(identifier: identifier, in: pool) {
                    return match
                }
            }
        }

        if let enhanced = pool.filter({ $0.quality == .enhanced }).max(by: voiceSort) {
            return enhanced
        }
        if #available(iOS 16.0, *), let premium = pool.filter({ $0.quality == .premium }).max(by: voiceSort) {
            return premium
        }
        if let preferred = preferredNamedVoice(in: pool, languageCode: languageCode) {
            return preferred
        }

        let baseCode = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return AVSpeechSynthesisVoice(language: languageCode)
            ?? AVSpeechSynthesisVoice(language: baseCode)
    }

    static func voicePool(for languageCode: String) -> [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let exactMatches = allVoices.filter { $0.language == languageCode }
        let baseCode = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        let regionalMatches = exactMatches.isEmpty
            ? allVoices.filter { $0.language.hasPrefix(baseCode) }
            : exactMatches
        return regionalMatches.isEmpty ? allVoices.filter { $0.language.hasPrefix(baseCode) } : regionalMatches
    }

    static func voiceMatching(identifier: String, in pool: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        if let exact = pool.first(where: { $0.identifier == identifier }) {
            return exact
        }
        if let contains = pool.first(where: { $0.identifier.localizedCaseInsensitiveContains(identifier) }) {
            return contains
        }
        guard let leaf = identifier.split(separator: ".").last.map(String.init), leaf.count > 2 else {
            return nil
        }
        return pool.first { voice in
            voice.identifier.localizedCaseInsensitiveContains(leaf)
                || voice.name.localizedCaseInsensitiveContains(leaf)
        }
    }

    static func tier(for voice: AVSpeechSynthesisVoice) -> VoiceQualityTier {
        switch voice.quality {
        case .premium:
            return .premium
        case .enhanced:
            return .enhanced
        case .default:
            if voice.identifier.contains("super-compact") || voice.identifier.contains("compact") {
                return .compact
            }
            return .compact
        @unknown default:
            return .unknown
        }
    }

    static func preferredNamedVoice(in pool: [AVSpeechSynthesisVoice], languageCode: String) -> AVSpeechSynthesisVoice? {
        let names: [String]
        switch languageCode {
        case "en-US", "en-GB":
            names = ["Samantha", "Alex", "Daniel"]
        case "sv-SE":
            names = ["Alva", "Oskar"]
        case "es-ES":
            names = ["Mónica", "Monica", "Jorge"]
        case "de-DE":
            names = ["Anna", "Petra", "Markus", "Martin"]
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
