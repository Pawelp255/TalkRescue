import AVFoundation
import Foundation
import os
import Speech

@MainActor
final class SpeechManager: ObservableObject {
    @Published private(set) var recognizedText = ""
    /// True only when mic tap, audio engine, and speech task are all active.
    @Published private(set) var isRecognizerReady = false
    /// True while start pipeline is running (permissions, session, engine).
    @Published private(set) var isStartingCapture = false
    @Published var errorMessage: String?

    /// Backward-compatible: same as isRecognizerReady during capture.
    var isRecording: Bool { isRecognizerReady }

    var onInterruption: (() -> Void)?

    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Speech")
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStoppingIntentionally = false
    private var finalizeContinuation: CheckedContinuation<Void, Never>?
    private var readinessContinuation: CheckedContinuation<Void, Never>?
    private var isPrewarmed = false
    private var hasReceivedAudioBuffer = false
    private var startGeneration = 0

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))
            ?? SFSpeechRecognizer(locale: Locale(identifier: "pl"))
        if speechRecognizer == nil {
            logger.error("Polish speech recognizer could not be created.")
        }
        observeAudioInterruptions()
    }

    var hasPermissions: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
            && AVAudioApplication.shared.recordPermission == .granted
    }

    func clearError() {
        errorMessage = nil
    }

    func setRecognizedTextForDisplay(_ text: String) {
        recognizedText = text
    }

    func clearRecognizedText() {
        recognizedText = ""
    }

    func prewarmIfPermitted() async {
        guard hasPermissions else { return }
        guard !isPrewarmed else { return }

        let started = Date()
        _ = speechRecognizer?.isAvailable
        isPrewarmed = true
        LaunchMetrics.log("Speech prewarm", since: started)
        logger.info("Speech recognizer prewarmed.")
    }

    /// Full teardown between rescue sessions — avoids stale engine state.
    func fullCleanup() async {
        let started = Date()
        let generation = startGeneration + 1
        startGeneration = generation

        isStoppingIntentionally = true
        defer { isStoppingIntentionally = false }

        clearListeningState()
        tearDownRecognitionPipeline()
        deactivateAudioSession()

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()

        guard generation == startGeneration else { return }

        LaunchMetrics.log("Speech cleanup", since: started)
        logger.info("Cleanup completed.")
    }

    func startRecording() async {
        guard !isRecognizerReady, !isStartingCapture else {
            logger.info("Recording already active or starting — ignored duplicate request.")
            return
        }

        let startRequested = Date()
        let generation = startGeneration + 1
        startGeneration = generation

        isStartingCapture = true
        clearListeningState()
        errorMessage = nil
        recognizedText = ""
        tearDownRecognitionPipeline()

        let initStarted = Date()
        defer {
            if generation == startGeneration {
                isStartingCapture = false
            }
        }

        do {
            try await requestPermissions()
            guard generation == startGeneration, !Task.isCancelled else {
                logger.info("Recording start cancelled after permissions.")
                tearDownRecognitionPipeline()
                deactivateAudioSession()
                return
            }
            try configureAudioSessionForRecording()
            try startRecognitionPipeline(generation: generation)
            await waitForRecognizerReady(generation: generation, timeoutSeconds: 0.4)
            guard generation == startGeneration else { return }

            guard audioEngine.isRunning, recognitionTask != nil, hasReceivedAudioBuffer else {
                throw SpeechError.pipelineNotReady
            }

            isRecognizerReady = true
            LaunchMetrics.log("Speech init-to-ready", since: initStarted)
            LaunchMetrics.log("Speech tap-to-ready", since: startRequested)
            logger.info("Recognizer truly ready — listening UI may activate.")
            logger.info("Audio engine started.")
            logger.info("Speech task active.")
        } catch {
            clearListeningState()
            tearDownRecognitionPipeline()
            deactivateAudioSession()
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            logger.error("Recording start failure: \(error.localizedDescription, privacy: .public)")
        }
    }

    func endRecordingAndFinalize() async -> String {
        guard isRecognizerReady || audioEngine.isRunning || recognitionRequest != nil else {
            return recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        isStoppingIntentionally = true
        defer { isStoppingIntentionally = false }

        recognitionRequest?.endAudio()
        stopAudioCapture()

        await waitForFinalTranscript(timeoutSeconds: 0.25)

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        clearListeningState()
        deactivateAudioSession()

        let text = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.info("Recording ended. transcriptLength=\(text.count, privacy: .public)")
        return text
    }

    func stopRecording() {
        guard isRecognizerReady || isStartingCapture || audioEngine.isRunning || recognitionRequest != nil else {
            return
        }

        startGeneration += 1
        isStoppingIntentionally = true
        defer { isStoppingIntentionally = false }

        tearDownRecognitionPipeline()
        clearListeningState()
        deactivateAudioSession()
        logger.debug("Recording stopped without finalize.")
    }

    private func clearListeningState() {
        isRecognizerReady = false
        hasReceivedAudioBuffer = false
        completeReadinessIfNeeded()
    }

    private func waitForFinalTranscript(timeoutSeconds: TimeInterval) async {
        await withCheckedContinuation { continuation in
            finalizeContinuation = continuation

            Task { @MainActor in
                let nanoseconds = UInt64(timeoutSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                completeFinalizationIfNeeded()
            }
        }
    }

    private func waitForRecognizerReady(generation: Int, timeoutSeconds: TimeInterval) async {
        if hasReceivedAudioBuffer, audioEngine.isRunning, recognitionTask != nil {
            return
        }

        await withCheckedContinuation { continuation in
            readinessContinuation = continuation

            Task { @MainActor in
                let nanoseconds = UInt64(timeoutSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard generation == self.startGeneration else {
                    self.completeReadinessIfNeeded()
                    return
                }
                if self.hasReceivedAudioBuffer {
                    self.logger.info("Recognizer ready after first audio buffer.")
                } else {
                    self.logger.info("Recognizer ready after readiness timeout fallback.")
                }
                self.completeReadinessIfNeeded()
            }
        }
    }

    private func completeReadinessIfNeeded() {
        guard let continuation = readinessContinuation else { return }
        readinessContinuation = nil
        continuation.resume()
    }

    private func completeFinalizationIfNeeded() {
        guard let continuation = finalizeContinuation else { return }
        finalizeContinuation = nil
        continuation.resume()
    }

    private func requestPermissions() async throws {
        if hasPermissions { return }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            throw SpeechError.speechPermissionDenied
        }

        let microphoneGranted = await AVAudioApplication.requestRecordPermission()
        guard microphoneGranted else {
            throw SpeechError.microphonePermissionDenied
        }
    }

    private func configureAudioSessionForRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setPreferredInputNumberOfChannels(1)
        try? audioSession.setPreferredIOBufferDuration(0.01)
        try? audioSession.setPreferredSampleRate(44_100)
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.debug("Audio session deactivation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func startRecognitionPipeline(generation: Int) throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = false
        request.contextualStrings = [
            "proszę powtórzyć",
            "nie rozumiem",
            "potrzebuję chwili",
            "proszę mówić wolniej",
            "zaraz sprawdzę"
        ]
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        if #available(iOS 13.0, *) {
            try? inputNode.setVoiceProcessingEnabled(true)
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }

        hasReceivedAudioBuffer = false
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self, weak request] buffer, _ in
            guard let request else { return }
            request.append(buffer)
            Task { @MainActor in
                guard let self, generation == self.startGeneration else { return }
                if !self.hasReceivedAudioBuffer {
                    self.hasReceivedAudioBuffer = true
                    self.logger.info("First audio buffer received — tap active.")
                    self.completeReadinessIfNeeded()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    let text = result.bestTranscription.formattedString
                    if Self.isLikelyGarbagePartial(text, previous: self.recognizedText) {
                        return
                    }
                    self.recognizedText = text
                    if result.isFinal {
                        self.completeFinalizationIfNeeded()
                    }
                }

                if let error, !self.shouldIgnoreRecognitionError(error) {
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Recognition error: \(error.localizedDescription, privacy: .public)")
                    if self.isRecognizerReady {
                        self.stopRecording()
                    }
                }
            }
        }
        logger.info("Speech task active.")
    }

    private static func isLikelyGarbagePartial(_ text: String, previous: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if previous.isEmpty { return trimmed.count < 2 }
        if trimmed.count < 2, previous.count >= 2 { return true }
        return false
    }

    private func stopAudioCapture() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        let inputNode = audioEngine.inputNode
        if inputNode.numberOfInputs > 0 {
            inputNode.removeTap(onBus: 0)
        }
    }

    private func tearDownRecognitionPipeline() {
        stopAudioCapture()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        completeFinalizationIfNeeded()
        completeReadinessIfNeeded()
    }

    private func shouldIgnoreRecognitionError(_ error: Error) -> Bool {
        if isStoppingIntentionally {
            return true
        }

        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 216 {
            return true
        }

        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 209 {
            return true
        }

        if nsError.localizedDescription.lowercased().contains("cancel") {
            return true
        }

        return false
    }

    private func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let type = AVAudioSession.InterruptionType(rawValue: typeValue ?? 0)
            if type == .began {
                Task { @MainActor in
                    self.logger.info("Audio session interrupted.")
                    if self.isRecognizerReady || self.isStartingCapture {
                        self.stopRecording()
                    }
                    self.onInterruption?()
                }
            }
        }
    }
}

enum SpeechError: LocalizedError {
    case speechPermissionDenied
    case microphonePermissionDenied
    case recognizerUnavailable
    case pipelineNotReady

    var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Wymagane jest pozwolenie na rozpoznawanie mowy."
        case .microphonePermissionDenied:
            return "Wymagane jest pozwolenie na mikrofon."
        case .recognizerUnavailable:
            return "Rozpoznawanie polskiego jest teraz niedostępne."
        case .pipelineNotReady:
            return "Mikrofon nie jest jeszcze gotowy. Spróbuj ponownie."
        }
    }
}
