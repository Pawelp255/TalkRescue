import SwiftUI
import os

/// Ultra-fast, distraction-free rescue UI for stressful conversations.
struct RescueModeView: View {
    @ObservedObject var session: RescueSession
    @EnvironmentObject private var launchCoordinator: RescueLaunchCoordinator

    @AppStorage("autoSpeakEnglish") private var autoSpeakEnglish = false

    @State private var micPulse = false
    @State private var waveformPhase = false
    @State private var statusPulse = false
    @State private var processingAnimating = false
    @State private var lastObservedRequestID: UInt = 0
    @State private var readyPulse = false
    @State private var requestTask: Task<Void, Never>?

    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "RescueMode")

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.rescueBackgroundTop, AppTheme.rescueBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: AppTheme.sectionSpacing) {
                HStack {
                    Spacer()
                    Button {
                        session.cancelRescueAutoListen()
                        session.cancelActiveWork()
                        launchCoordinator.dismissRescueMode()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(minWidth: AppTheme.minTapTarget, minHeight: AppTheme.minTapTarget)
                    .accessibilityLabel("Zamknij tryb ratunkowy")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                statusBanner
                    .padding(.horizontal, 20)

                if session.isFinalizingRecording || session.isTranslating {
                    processingIndicator
                        .padding(.horizontal, 20)
                }

                if session.isPreparingToListen || session.isListeningReady {
                    speechActivityIndicator
                        .padding(.horizontal, 20)
                }

                englishResult
                    .padding(.horizontal, 20)

                Toggle(L10n.Rescue.autoSpeak, isOn: $autoSpeakEnglish)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .onChange(of: autoSpeakEnglish) { _, value in
                        session.autoSpeakEnglish = value
                    }

                Spacer(minLength: 8)

                doneButton
                    .padding(.horizontal, 20)

                secondaryActions
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            logger.info("Rescue Mode appeared.")
            autoSpeakEnglish = session.autoSpeakEnglish
            processingAnimating = true
            handleRescueRequest(launchCoordinator.rescueRequestID, reason: "onAppear")
        }
        .onChange(of: launchCoordinator.rescueRequestID) { _, requestID in
            logger.info("RescueMode observed request id=\(requestID, privacy: .public)")
            handleRescueRequest(requestID, reason: "requestID")
        }
        .onDisappear {
            logger.info("Rescue Mode disappeared.")
            requestTask?.cancel()
            requestTask = nil
            session.cancelRescueAutoListen()
            session.cancelActiveWork()
            lastObservedRequestID = 0
        }
    }

    private func handleRescueRequest(_ requestID: UInt, reason: String) {
        guard requestID > 0 else { return }
        guard launchCoordinator.shouldAutoListen(for: requestID) else {
            logger.info("Request ignored — already handled id=\(requestID, privacy: .public)")
            return
        }
        guard requestID > lastObservedRequestID else {
            logger.info("Request ignored — stale id=\(requestID, privacy: .public)")
            return
        }

        lastObservedRequestID = requestID
        requestTask?.cancel()
        requestTask = Task {
            await session.prepareForNewRescueRequest()
            guard !Task.isCancelled else { return }
            session.startRescueAutoListenIfNeeded(
                reason: reason,
                force: false,
                requestID: requestID,
                coordinator: launchCoordinator
            )
        }
    }

    private func requestAutoListen(reason: String, force: Bool = false) {
        guard force || reason == "tapListen" else { return }
        guard !session.isTranslating, !session.isFinalizingRecording else { return }

        session.startRescueAutoListenIfNeeded(
            reason: reason,
            force: force,
            requestID: launchCoordinator.rescueRequestID,
            coordinator: launchCoordinator
        )
    }

    private var statusBanner: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .scaleEffect((statusPulse && isBusyState) || readyPulse ? 1.2 : 1.0)
                .animation(
                    isBusyState
                        ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                        : .default,
                    value: statusPulse
                )

            Text(rescueStatusText)
                .font(.title3.weight(.bold))
                .foregroundStyle(statusColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.cardPadding)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(statusColor.opacity(isActiveState ? 0.14 : 0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius)
                .strokeBorder(statusColor.opacity(isActiveState ? 0.36 : 0.14), lineWidth: 1)
        )
        .shadow(color: statusColor.opacity(isActiveState ? 0.16 : 0), radius: 18, y: 6)
        .animation(.easeInOut(duration: 0.22), value: rescueStatusText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rescueStatusText)
        .onChange(of: isBusyState) { _, busy in
            statusPulse = busy
        }
        .onAppear { statusPulse = isBusyState }
    }

    private var processingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(AppTheme.translating)
                .scaleEffect(0.9)
            Text(session.isFinalizingRecording ? L10n.Main.finishingCapture : L10n.Main.gettingEnglish)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(processingAnimating ? 1 : 0.6)
        .animation(.easeInOut(duration: 0.25), value: processingAnimating)
        .onAppear { processingAnimating = true }
    }

    private var isBusyState: Bool {
        session.isFinalizingRecording || session.isTranslating
    }

    private var speechActivityIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: 8, height: barHeight(for: index))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .opacity(session.isPreparingToListen ? 0.75 : 1)
        .animation(.easeInOut(duration: 0.35), value: session.rescueSpeechDetected)
        .animation(.easeInOut(duration: 0.35), value: session.isListeningReady)
        .animation(.easeInOut(duration: 0.35), value: waveformPhase)
        .onAppear {
            waveformPhase = true
        }
        .accessibilityHidden(true)
    }

    private var barColor: Color {
        if session.isListeningReady {
            return AppTheme.rescueRecording.opacity(session.rescueSpeechDetected ? 0.95 : 0.55)
        }
        if session.isPreparingToListen {
            return AppTheme.preparing.opacity(0.5)
        }
        return Color.white.opacity(0.25)
    }

    private func barHeight(for index: Int) -> CGFloat {
        if session.isPreparingToListen { return [12, 16, 18, 14, 12][index] }
        guard session.isListeningReady else { return 10 }
        let heights: [CGFloat] = [18, 28, 34, 26, 20]
        return heights[index]
    }

    private var rescueStatusText: String {
        if session.isTranslating { return L10n.Rescue.translating }
        if session.isFinalizingRecording { return L10n.Rescue.processing }
        if session.isSpeaking { return L10n.Rescue.speaking }
        if session.isPreparingToListen { return L10n.Rescue.preparingMic }
        if session.statusMessage == L10n.Main.noSpeechDetected {
            return L10n.Rescue.noSpeech
        }
        if session.isListeningReady {
            return session.rescueSpeechDetected ? L10n.Rescue.recordingPolish : L10n.Rescue.ready
        }
        if let error = session.speechManager.errorMessage { return error }
        if session.showTranslationError { return session.statusMessage }
        if !session.englishText.isEmpty { return L10n.Rescue.done }
        return L10n.Rescue.preparingMic
    }

    private var isActiveState: Bool {
        session.isPreparingToListen
            || session.isListeningReady
            || session.isFinalizingRecording
            || session.isTranslating
            || session.isSpeaking
    }

    private var englishResult: some View {
        Text(session.englishText.isEmpty ? L10n.Rescue.englishPlaceholder : session.englishText)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(session.englishText.isEmpty ? .white.opacity(0.35) : .white)
            .minimumScaleFactor(0.45)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        session.lastTranslationWasInstant
                            ? AppTheme.rescueReady.opacity(0.14)
                            : AppTheme.rescueSurface
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(
                        session.lastTranslationWasInstant ? AppTheme.rescueReady.opacity(0.35) : AppTheme.darkHairline,
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: session.englishText)
            .animation(.easeInOut(duration: 0.2), value: session.lastTranslationWasInstant)
            .accessibilityLabel(session.englishText.isEmpty ? L10n.Rescue.englishPlaceholder : session.englishText)
    }

    private var doneButton: some View {
        Button {
            if session.isListeningReady {
                session.finishRecordingAndTranslate(source: "manual-finish")
            } else if !session.isTranslating, !session.isSpeaking, !session.isFinalizingRecording {
                requestAutoListen(reason: "tapListen", force: true)
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: session.isListeningReady ? "checkmark.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .scaleEffect(session.isListeningReady && micPulse ? 1.1 : 1.0)
                    .animation(
                        session.isListeningReady
                            ? .easeInOut(duration: 0.75).repeatForever(autoreverses: true)
                            : .default,
                        value: micPulse
                    )

                Text(doneButtonLabel)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if session.isListeningReady {
                    Text(L10n.Rescue.autoContinueHint)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 188)
            .background(doneButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: doneButtonColor.opacity(isActiveState ? 0.30 : 0.18), radius: 24, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(session.isTranslating || session.isFinalizingRecording)
        .opacity(session.isTranslating || session.isFinalizingRecording ? 0.8 : 1)
        .accessibilityLabel(doneButtonLabel)
        .onChange(of: session.isListeningReady) { _, ready in
            micPulse = ready
            readyPulse = ready
        }
        .onAppear { micPulse = session.isListeningReady }
    }

    @ViewBuilder
    private var secondaryActions: some View {
        HStack(spacing: 12) {
            Button(L10n.Rescue.tryAgain) {
                logger.info("Try again tapped — restarting listening.")
                session.tryAgainListening()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .controlSize(.large)
            .frame(minHeight: AppTheme.minTapTarget)
            .disabled(session.isTranslating || session.isFinalizingRecording || session.isListeningReady || session.isPreparingToListen)

            if session.showTranslationError, session.retryPolishText != nil {
                Button(L10n.Rescue.retryTranslation) {
                    session.retryTranslation()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .controlSize(.large)
                .frame(minHeight: AppTheme.minTapTarget)
                .disabled(session.isTranslating)
            }
        }
    }

    private var doneButtonLabel: String {
        if session.isTranslating { return L10n.Rescue.translating }
        if session.isFinalizingRecording { return L10n.Rescue.processing }
        if session.isListeningReady { return L10n.Rescue.tapWhenDone }
        if session.isSpeaking { return L10n.Rescue.speaking }
        if session.isPreparingToListen { return L10n.Rescue.preparingMic }
        return L10n.Rescue.tapToListen
    }

    private var doneButtonColor: Color {
        if session.isFinalizingRecording { return AppTheme.translating }
        if session.isListeningReady { return AppTheme.listening }
        if session.isPreparingToListen { return AppTheme.preparing }
        if session.isTranslating { return AppTheme.translating }
        return AppTheme.micIdle
    }

    private var doneButtonBackground: LinearGradient {
        LinearGradient(
            colors: [doneButtonColor.opacity(0.92), doneButtonGradientBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var doneButtonGradientBottom: Color {
        if session.isFinalizingRecording || session.isTranslating {
            return Color(red: 0.62, green: 0.35, blue: 0.12)
        }
        if session.isListeningReady {
            return Color(red: 0.50, green: 0.18, blue: 0.24)
        }
        if session.isPreparingToListen {
            return Color(red: 0.64, green: 0.36, blue: 0.12)
        }
        return Color(red: 0.10, green: 0.25, blue: 0.48)
    }

    private var statusColor: Color {
        if session.statusMessage == L10n.Main.noSpeechDetected { return .white.opacity(0.75) }
        if session.isFinalizingRecording { return AppTheme.translating }
        if session.isListeningReady {
            return session.rescueSpeechDetected ? AppTheme.rescueRecording : AppTheme.rescueReady
        }
        if session.isPreparingToListen { return AppTheme.preparing }
        if session.isTranslating { return AppTheme.translating }
        if session.isSpeaking { return AppTheme.rescueReady }
        if session.showTranslationError || session.speechManager.errorMessage != nil {
            return Color(red: 0.95, green: 0.45, blue: 0.45)
        }
        if !session.englishText.isEmpty { return AppTheme.rescueReady }
        return .white.opacity(0.7)
    }
}
