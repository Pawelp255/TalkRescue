import Combine
import Foundation
import os
import SwiftUI

/// Shared rescue workflow: speech → translation → TTS.
/// Used by normal mode and Rescue Mode so shortcuts/widgets can share one path later.
@MainActor
final class RescueSession: ObservableObject {
    let speechManager = SpeechManager()

    @Published var englishText = ""
    @Published var statusMessage = L10n.Main.defaultStatus
    @Published var isTranslating = false
    @Published var lastPolishText = ""
    @Published var showTranslationError = false
    @Published private(set) var isSpeaking = false
    @Published private(set) var isFinalizingRecording = false
    @Published private(set) var rescueSpeechDetected = false
    @Published private(set) var lastTranslationWasInstant = false

    var isPreparingToListen: Bool { speechManager.isStartingCapture }
    var isListeningReady: Bool { speechManager.isRecognizerReady }

    let profileStore: LanguageProfileStore

    private let phraseStore: PhraseStore
    private let translationService = TranslationService()
    private let ttsService = TTSService()
    private let silenceMonitor = RescueSilenceMonitor()
    private let noSpeechMonitor = NoSpeechTimeoutMonitor()
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "RescueSession")

    private var translationTask: Task<Void, Never>?
    private var translationGeneration = 0
    private var isFinishInProgress = false
    private var rescueAutoListenTask: Task<Void, Never>?
    private var rescueAutoListenGeneration = 0
    private var restartListeningTask: Task<Void, Never>?
    private var mainRecordingTask: Task<Void, Never>?
    private var mainHoldReleaseTask: Task<Void, Never>?
    private var mainRecordingGeneration = 0
    private enum RecordingContext {
        case none
        case mainHold
        case rescue
    }
    private var recordingContext: RecordingContext = .none
    private var cancellables = Set<AnyCancellable>()

    var autoSpeakEnglish: Bool {
        get { UserDefaults.standard.bool(forKey: "autoSpeakEnglish") }
        set { UserDefaults.standard.set(newValue, forKey: "autoSpeakEnglish") }
    }

    init(phraseStore: PhraseStore, profileStore: LanguageProfileStore) {
        self.phraseStore = phraseStore
        self.profileStore = profileStore
        speechManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        profileStore.$selectedProfile
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.applyLanguageProfile(profile)
            }
            .store(in: &cancellables)
        speechManager.onInterruption = { [weak self] in
            Task { @MainActor in
                self?.handleAudioInterruption()
            }
        }
        ttsService.onSpeakingChanged = { [weak self] speaking in
            self?.isSpeaking = speaking
        }
        applyLanguageProfile(profileStore.selectedProfile)
        #if DEBUG
        RescuePhraseCache.validateLookup()
        #endif
        Task { await prewarmServices() }
    }

    func prewarmServices() async {
        let started = Date()
        await speechManager.prewarmIfPermitted()
        await TranslationService.warmConnection()
        applyLanguageProfile(profileStore.selectedProfile)
        LaunchMetrics.log("Rescue prewarm total", since: started)
    }

    private func applyLanguageProfile(_ profile: LanguageProfile) {
        ttsService.prepare(voiceLanguage: profile.ttsVoiceLanguage)
    }

    var retryPolishText: String? {
        for candidate in [lastPolishText, speechManager.recognizedText] {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    func statusLabel(isRescueMode: Bool = false) -> String {
        if isTranslating { return L10n.Rescue.translating }
        if isSpeaking { return L10n.Rescue.speaking }
        if speechManager.isStartingCapture {
            return L10n.Rescue.preparingMic
        }
        if speechManager.isRecognizerReady {
            if isRescueMode, rescueSpeechDetected {
                return L10n.Rescue.recordingPolish
            }
            return isRescueMode ? L10n.Rescue.ready : L10n.Main.recordingPolish
        }
        if statusMessage == L10n.Main.noSpeechDetected
            || statusMessage == L10n.Main.shortTapNoSpeech
            || statusMessage == L10n.Rescue.noSpeech {
            return statusMessage
        }
        if let errorMessage = speechManager.errorMessage { return errorMessage }
        if showTranslationError { return statusMessage }
        if !translationService.isConfigured {
            return L10n.Main.apiKeyMissing
        }
        if !englishText.isEmpty, !isTranslating, !isFinalizingRecording {
            return isRescueMode ? L10n.Rescue.done : L10n.Main.ready
        }
        return statusMessage
    }

    /// Main-mode hold-to-speak entry. Tracked so a short tap can cancel in-flight startup.
    func requestBeginRecording() {
        guard recordingContext != .rescue else {
            logger.info("Recording request ignored — rescue owns mic.")
            return
        }
        guard !speechManager.isRecognizerReady, !speechManager.isStartingCapture else {
            logger.info("Recording request ignored — already active.")
            return
        }

        recordingContext = .mainHold
        logger.info("Recording requested (main hold).")
        mainRecordingTask?.cancel()
        let generation = mainRecordingGeneration
        mainRecordingTask = Task { @MainActor in
            await beginRecording(mainRecordingGeneration: generation)
        }
    }

    /// Called when the user lifts their finger from the main hold button.
    func handleMainHoldEnded() {
        mainHoldReleaseTask?.cancel()
        mainHoldReleaseTask = Task { @MainActor in
            logger.info("Stop requested (main hold ended).")

            if speechManager.isRecognizerReady {
                logger.info("Recognizer ready — finishing main hold.")
                finishRecordingAndTranslate(source: "recording")
                return
            }

            // Grace: gesture can end spuriously while startup is still running; wait before cancelling.
            let graceDeadline = Date().addingTimeInterval(0.9)
            while Date() < graceDeadline {
                if Task.isCancelled { return }
                if speechManager.isRecognizerReady {
                    logger.info("Recognizer ready during grace — finishing main hold.")
                    finishRecordingAndTranslate(source: "recording")
                    return
                }
                if !speechManager.isStartingCapture, recordingContext != .mainHold {
                    break
                }
                if !speechManager.isStartingCapture, !speechManager.isRecognizerReady {
                    break
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            if speechManager.isRecognizerReady {
                finishRecordingAndTranslate(source: "recording")
                return
            }

            cancelMainRecordingStartup()
        }
    }

    /// Cancels main-mode mic startup when the user releases before listening is ready.
    func cancelMainRecordingStartup() {
        guard recordingContext == .mainHold
            || speechManager.isStartingCapture
            || speechManager.isRecognizerReady else {
            logger.info("Main cancel ignored — no active main hold.")
            return
        }

        mainRecordingGeneration += 1
        logger.info("Generation invalidated (main cancel).")
        mainRecordingTask?.cancel()
        mainRecordingTask = nil
        mainHoldReleaseTask?.cancel()
        mainHoldReleaseTask = nil
        recordingContext = .none
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        let wasPreparing = speechManager.isStartingCapture
        let wasReady = speechManager.isRecognizerReady
        speechManager.stopRecording()
        stopSpeaking()
        speechManager.clearRecognizedText()
        speechManager.clearError()
        showTranslationError = false
        lastPolishText = ""
        lastTranslationWasInstant = false
        statusMessage = L10n.Main.shortTapNoSpeech
        if wasPreparing || wasReady {
            logger.info("Mic startup cancelled.")
        } else {
            logger.info("Short tap cancelled before ready.")
        }
    }

    func beginRecording(mainRecordingGeneration: Int? = nil) async {
        let isMainHold = mainRecordingGeneration != nil
        if isMainHold {
            if mainRecordingGeneration != self.mainRecordingGeneration {
                logger.info("Generation invalidated — main begin skipped.")
                return
            }
            recordingContext = .mainHold
        } else {
            recordingContext = .rescue
        }

        logger.info("Begin recording pipeline context=\(isMainHold ? "main" : "rescue", privacy: .public)")

        let started = Date()
        resetFinishState()
        speechManager.clearError()
        showTranslationError = false
        stopSpeaking()
        await speechManager.startRecording()

        if isMainHold, mainRecordingGeneration != self.mainRecordingGeneration {
            logger.info("Generation invalidated — stopping main startup after pipeline.")
            speechManager.stopRecording()
            if recordingContext == .mainHold { recordingContext = .none }
            return
        }

        if speechManager.isRecognizerReady {
            HapticFeedback.recordingStarted()
            LaunchMetrics.log("Begin recording ready", since: started)
            logger.info("Recognizer ready — listening UI activated.")
            if isMainHold {
                startNoSpeechMonitorIfNeeded()
            }
        } else {
            if recordingContext != .none { recordingContext = .none }
            if isMainHold {
                logger.info("Main recording startup ended without ready state.")
            } else {
                logger.error("Recording failed to start.")
            }
        }
    }

    func beginRescueRecordingWithSilenceMonitor() async {
        if speechManager.isRecognizerReady {
            logger.info("Recording already active — attaching silence monitor only.")
            attachSilenceMonitorIfNeeded()
            return
        }

        await beginRecording()
        guard speechManager.isRecognizerReady else { return }
        attachSilenceMonitorIfNeeded()
    }

    func cancelRescueAutoListen() {
        rescueAutoListenGeneration += 1
        rescueAutoListenTask?.cancel()
        rescueAutoListenTask = nil
    }

    /// Stop active work safely before handling a new Action Button / shortcut request.
    func prepareForNewRescueRequest() async {
        let wasBusy = isTranslating || isSpeaking || isFinalizingRecording
            || speechManager.isRecognizerReady || speechManager.isStartingCapture || isFinishInProgress

        mainRecordingGeneration += 1
        mainRecordingTask?.cancel()
        mainRecordingTask = nil
        mainHoldReleaseTask?.cancel()
        mainHoldReleaseTask = nil
        cancelRescueAutoListen()
        restartListeningTask?.cancel()
        restartListeningTask = nil
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        stopSpeaking()
        showTranslationError = false
        recordingContext = .none
        await speechManager.fullCleanup()

        if wasBusy {
            logger.info("Session reset before new rescue request.")
        }
    }

    /// Single entry point for Rescue Mode auto-listen. Safe against duplicate calls per request ID.
    func startRescueAutoListenIfNeeded(
        reason: String,
        force: Bool,
        requestID: UInt,
        coordinator: RescueLaunchCoordinator
    ) {
        guard force || coordinator.shouldAutoListen(for: requestID) else { return }
        guard !isTranslating, !isFinalizingRecording, !isFinishInProgress else {
            logger.info("Auto-start skipped — session busy requestId=\(requestID, privacy: .public)")
            return
        }
        if speechManager.isRecognizerReady || speechManager.isStartingCapture {
            logger.info("Recording already active — auto-start skipped requestId=\(requestID, privacy: .public)")
            if !force { coordinator.finishAutoListenAttempt(requestID: requestID) }
            return
        }
        guard coordinator.beginAutoListenAttempt(requestID: requestID, force: force) else { return }

        rescueAutoListenTask?.cancel()
        rescueAutoListenGeneration += 1
        let autoListenGeneration = rescueAutoListenGeneration
        rescueAutoListenTask = Task { @MainActor in
            defer {
                coordinator.finishAutoListenAttempt(requestID: requestID)
            }

            logger.info("Auto-listen started requestId=\(requestID, privacy: .public) reason=\(reason, privacy: .public)")

            guard autoListenGeneration == rescueAutoListenGeneration, !Task.isCancelled else { return }
            guard !speechManager.isRecognizerReady else {
                logger.info("Recording already active before auto-start.")
                return
            }

            await beginRescueRecordingWithSilenceMonitor()
            guard autoListenGeneration == rescueAutoListenGeneration, !Task.isCancelled else { return }
            if speechManager.isRecognizerReady {
                LaunchMetrics.logSinceLaunch("Launch-to-listening")
                logger.info("Recording start success requestId=\(requestID, privacy: .public)")
            } else {
                logger.error("Recording start failure requestId=\(requestID, privacy: .public)")
                statusMessage = L10n.Main.couldNotListen
            }
        }
    }

    private func attachSilenceMonitorIfNeeded() {
        guard !silenceMonitor.isMonitoring else { return }

        silenceMonitor.start(
            transcriptProvider: { [weak self] in
                self?.speechManager.recognizedText ?? ""
            },
            isRecordingProvider: { [weak self] in
                self?.speechManager.isRecognizerReady ?? false
            },
            onSpeechDetected: { [weak self] detected in
                self?.rescueSpeechDetected = detected
            },
            onAutoFinish: { [weak self] in
                self?.finishRecordingAndTranslate(source: "silence-auto-finish")
            }
        )
    }

    func stopRescueSilenceMonitor() {
        silenceMonitor.stop()
        rescueSpeechDetected = false
    }

    func stopNoSpeechMonitor() {
        noSpeechMonitor.stop()
    }

    func stopListeningMonitors() {
        stopRescueSilenceMonitor()
        stopNoSpeechMonitor()
    }

    private func startNoSpeechMonitorIfNeeded() {
        guard !noSpeechMonitor.isMonitoring else { return }

        noSpeechMonitor.start(
            transcriptProvider: { [weak self] in
                self?.speechManager.recognizedText ?? ""
            },
            isListeningProvider: { [weak self] in
                self?.speechManager.isRecognizerReady ?? false
            },
            onTimeout: { [weak self] in
                self?.handleNoSpeechTimeout()
            }
        )
    }

    func handleNoSpeechTimeout() {
        guard speechManager.isRecognizerReady else { return }
        guard !isFinishInProgress, !isTranslating, !isFinalizingRecording else { return }
        guard recordingContext == .mainHold else { return }

        logger.info("No-speech triggered — resetting to idle.")
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        speechManager.stopRecording()
        speechManager.clearRecognizedText()
        speechManager.clearError()
        showTranslationError = false
        lastPolishText = ""
        lastTranslationWasInstant = false
        recordingContext = .none
        statusMessage = L10n.Main.noSpeechDetected
    }

    func finishRecordingAndTranslate(source: String) {
        guard speechManager.isRecognizerReady, !isFinishInProgress else { return }

        stopListeningMonitors()
        isFinishInProgress = true
        isFinalizingRecording = true
        HapticFeedback.recordingStopped()

        if source == "silence-auto-finish" {
            logger.info("Silence auto-finish — finalizing recording.")
        } else {
            logger.info("Manual finish — finalizing recording source=\(source, privacy: .public)")
        }

        startTranslation(polishText: nil, source: source)
    }

    func startTranslation(polishText: String?, source: String) {
        translationTask?.cancel()
        translationGeneration += 1
        let generation = translationGeneration

        translationTask = Task { @MainActor in
            let polish: String
            if let polishText {
                polish = polishText
            } else {
                polish = await speechManager.endRecordingAndFinalize()
            }

            logger.debug("Translation started source=\(source, privacy: .public) generation=\(generation, privacy: .public)")
            await translateRecognizedSpeech(polish, generation: generation)
        }
    }

    func retryTranslation() {
        guard let polish = retryPolishText else {
            logger.error("Retry requested with no Polish text.")
            statusMessage = L10n.Main.nothingToRetry
            return
        }

        stopListeningMonitors()
        resetFinishState()
        logger.info("Retry translation requested.")
        speechManager.stopRecording()
        stopSpeaking()
        startTranslation(polishText: polish, source: "retry")
    }

    func prepareForFastPlayback() {
        ttsService.warmPlaybackSession()
    }

    func speakEnglish() {
        guard !englishText.isEmpty else { return }
        ttsService.speak(englishText)
    }

    func stopSpeaking() {
        ttsService.releasePlaybackForRecording()
    }

    func clearCurrentResult() {
        mainRecordingGeneration += 1
        mainRecordingTask?.cancel()
        mainRecordingTask = nil
        mainHoldReleaseTask?.cancel()
        mainHoldReleaseTask = nil
        recordingContext = .none
        cancelRescueAutoListen()
        restartListeningTask?.cancel()
        restartListeningTask = nil
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        speechManager.stopRecording()
        englishText = ""
        speechManager.clearRecognizedText()
        speechManager.clearError()
        statusMessage = L10n.Main.defaultStatus
        showTranslationError = false
        lastPolishText = ""
        lastTranslationWasInstant = false
        stopSpeaking()
    }

    func cancelActiveWork() {
        mainRecordingGeneration += 1
        mainRecordingTask?.cancel()
        mainRecordingTask = nil
        mainHoldReleaseTask?.cancel()
        mainHoldReleaseTask = nil
        recordingContext = .none
        cancelRescueAutoListen()
        restartListeningTask?.cancel()
        restartListeningTask = nil
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        speechManager.stopRecording()
        stopSpeaking()
    }

    func tryAgainListening() {
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        showTranslationError = false
        englishText = ""
        speechManager.clearRecognizedText()
        speechManager.clearError()
        lastPolishText = ""
        lastTranslationWasInstant = false
        stopSpeaking()
        statusMessage = L10n.Main.listenAgain
        logger.info("Try again — restarting listening.")

        restartListeningTask?.cancel()
        restartListeningTask = Task { @MainActor in
            await speechManager.fullCleanup()
            guard !Task.isCancelled else { return }
            await beginRescueRecordingWithSilenceMonitor()
        }
    }

    func handleBackground() {
        logger.info("App backgrounded — stopping active rescue work.")
        cancelRescueAutoListen()
        restartListeningTask?.cancel()
        restartListeningTask = nil
        stopListeningMonitors()
        resetFinishState()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        if speechManager.isRecognizerReady || speechManager.isStartingCapture {
            speechManager.stopRecording()
        }
        stopSpeaking()
    }

    func handleAudioInterruption() {
        logger.info("Audio interruption — stopping recording and TTS.")
        stopListeningMonitors()
        resetFinishState()
        speechManager.stopRecording()
        translationTask?.cancel()
        translationGeneration += 1
        isTranslating = false
        stopSpeaking()
        statusMessage = L10n.Main.interrupted
    }

    private func resetFinishState() {
        isFinishInProgress = false
        isFinalizingRecording = false
    }

    private func translateRecognizedSpeech(_ polishText: String, generation: Int) async {
        guard !Task.isCancelled, generation == translationGeneration else {
            logger.debug("Translation skipped: cancelled or superseded.")
            return
        }

        let trimmed = polishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isUsableTranscript(trimmed) else {
            resetFinishState()
            stopNoSpeechMonitor()
            speechManager.stopRecording()
            recordingContext = .none
            statusMessage = L10n.Main.noSpeechDetected
            speechManager.clearError()
            showTranslationError = false
            lastPolishText = ""
            lastTranslationWasInstant = false
            logger.info("No-speech triggered — empty transcript after finish.")
            return
        }

        isFinalizingRecording = false
        showTranslationError = false
        lastPolishText = trimmed
        lastTranslationWasInstant = false

        let profile = profileStore.selectedProfile

        // Local cache: synchronous, never races OpenAI (network only runs on miss).
        if let cached = RescuePhraseCache.translation(for: trimmed, profile: profile) {
            guard !Task.isCancelled, generation == translationGeneration else { return }
            logger.info("Local instant translation hit.")
            applyTranslationSuccess(
                polish: trimmed,
                english: cached,
                generation: generation,
                instant: true
            )
            return
        }

        guard !Task.isCancelled, generation == translationGeneration else { return }

        isTranslating = true
        defer {
            if generation == translationGeneration {
                isTranslating = false
                isFinishInProgress = false
            }
        }

        let started = Date()
        logger.info("Translation started (OpenAI).")

        do {
            let translation = try await translationService.translate(trimmed, profile: profile)
            guard !Task.isCancelled, generation == translationGeneration else { return }

            let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
            logger.info("Translation completed durationMs=\(elapsedMs, privacy: .public)")
            applyTranslationSuccess(
                polish: trimmed,
                english: translation,
                generation: generation,
                instant: false
            )
        } catch {
            guard !Task.isCancelled, generation == translationGeneration else { return }

            statusMessage = error.localizedDescription
            showTranslationError = true
            HapticFeedback.translationFailed()
            logger.error("Translation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applyTranslationSuccess(
        polish: String,
        english: String,
        generation: Int,
        instant: Bool
    ) {
        guard generation == translationGeneration else { return }

        lastTranslationWasInstant = instant
        englishText = english
        statusMessage = L10n.Main.ready
        speechManager.clearError()
        showTranslationError = false
        isFinalizingRecording = false
        isTranslating = false
        isFinishInProgress = false
        recordingContext = .none
        phraseStore.addToHistory(polishText: polish, englishText: english)
        HapticFeedback.translationSucceeded()
        logger.info("Translation succeeded instant=\(instant, privacy: .public)")

        if autoSpeakEnglish {
            ttsService.warmPlaybackSession()
            speakEnglish()
        }
    }

    private static func isUsableTranscript(_ text: String) -> Bool {
        let letters = text.filter(\.isLetter)
        guard letters.count >= 2 else { return false }

        let words = text.split(whereSeparator: \.isWhitespace)
        if words.count == 1, let word = words.first {
            return word.count >= 2
        }

        return true
    }
}
