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
    case basic
    case unknown

    var isHighQuality: Bool {
        self == .premium || self == .enhanced
    }

    var displayLabel: String {
        switch self {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        case .basic: return "Basic"
        case .unknown: return "Basic"
        }
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
            Self.logSelectedVoice(voice, languageCode: voiceLanguage, logger: logger, context: "prepare")
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

        if let voice {
            Self.logSelectedVoice(voice, languageCode: voiceLanguage, logger: logger, context: "speak")
        }
        logger.info(
            "TTS start length=\(trimmedText.count, privacy: .public) style=\(style.rawValue, privacy: .public)"
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
    static func resolveBestVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let exactPool = allVoices.filter { $0.language == languageCode }
        let regionalPool = regionalVoicePool(for: languageCode, in: allVoices)
        let selectionPool = selectionPool(
            exact: exactPool,
            regional: regionalPool
        )

        if let best = selectionPool.max(by: compareVoiceQuality) {
            return best
        }

        let baseCode = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return AVSpeechSynthesisVoice(language: languageCode)
            ?? AVSpeechSynthesisVoice(language: baseCode)
    }

    /// Exact `language` match first; include regional variants when exact tier is only basic.
    static func voicePool(for languageCode: String) -> [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let exactPool = allVoices.filter { $0.language == languageCode }
        let regionalPool = regionalVoicePool(for: languageCode, in: allVoices)
        return selectionPool(exact: exactPool, regional: regionalPool)
    }

    static func regionalVoicePool(for languageCode: String, in allVoices: [AVSpeechSynthesisVoice]) -> [AVSpeechSynthesisVoice] {
        let baseCode = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return allVoices.filter { voice in
            voice.language == baseCode || voice.language.hasPrefix("\(baseCode)-")
        }
    }

    static func selectionPool(
        exact: [AVSpeechSynthesisVoice],
        regional: [AVSpeechSynthesisVoice]
    ) -> [AVSpeechSynthesisVoice] {
        if exact.isEmpty {
            return regional
        }

        let exactBest = exact.max(by: compareVoiceQuality)
        let regionalBest = regional.max(by: compareVoiceQuality)

        guard let exactBest else { return exact }
        guard let regionalBest else { return exact }

        if qualityRank(for: exactBest) >= qualityRank(for: regionalBest) {
            return exact
        }

        if qualityRank(for: regionalBest) > qualityRank(for: exactBest) {
            return regional
        }

        return exact
    }

    static func compareVoiceQuality(_ lhs: AVSpeechSynthesisVoice, _ rhs: AVSpeechSynthesisVoice) -> Bool {
        let leftRank = qualityRank(for: lhs)
        let rightRank = qualityRank(for: rhs)
        if leftRank != rightRank {
            return leftRank < rightRank
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    static func qualityRank(for voice: AVSpeechSynthesisVoice) -> Int {
        switch voice.quality {
        case .premium:
            return 3
        case .enhanced:
            return 2
        case .default:
            return 1
        @unknown default:
            return 0
        }
    }

    static func qualityName(for voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium:
            return "premium"
        case .enhanced:
            return "enhanced"
        case .default:
            return "default"
        @unknown default:
            return "unknown"
        }
    }

    static func tier(for voice: AVSpeechSynthesisVoice) -> VoiceQualityTier {
        switch voice.quality {
        case .premium:
            return .premium
        case .enhanced:
            return .enhanced
        case .default:
            return .basic
        @unknown default:
            return .unknown
        }
    }

    static func logSelectedVoice(
        _ voice: AVSpeechSynthesisVoice,
        languageCode: String,
        logger: Logger,
        context: String
    ) {
        logger.info(
            """
            Selected voice (\(context, privacy: .public)) \
            name=\(voice.name, privacy: .public) \
            identifier=\(voice.identifier, privacy: .public) \
            language=\(voice.language, privacy: .public) \
            quality=\(qualityName(for: voice), privacy: .public) \
            requestedLang=\(languageCode, privacy: .public)
            """
        )
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
