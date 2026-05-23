import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var session: RescueSession
    @EnvironmentObject private var phraseStore: PhraseStore
    @EnvironmentObject private var launchCoordinator: RescueLaunchCoordinator

    @AppStorage("autoSpeakEnglish") private var autoSpeakEnglish = false

    private let quickPhrases = [
        "Can you repeat that?",
        "I need a moment.",
        "I don't understand.",
        "Let me check.",
        "I will call you back later."
    ]

    @State private var selectedTab: RescueTab = .main
    @State private var isHoldingRecordButton = false

    var body: some View {
        TabView(selection: $selectedTab) {
            mainView
                .tabItem { Label(L10n.Main.tabMain, systemImage: "mic.fill") }
                .tag(RescueTab.main)

            phraseListView(
                title: L10n.Main.tabHistory,
                phrases: phraseStore.history,
                emptyText: L10n.Main.noPhrasesYet,
                style: .history
            )
            .tabItem { Label(L10n.Main.tabHistory, systemImage: "clock.fill") }
            .tag(RescueTab.history)

            phraseListView(
                title: L10n.Main.tabFavorites,
                phrases: phraseStore.favorites,
                emptyText: L10n.Main.noFavoritesYet,
                style: .favorites,
                allowsDelete: true
            )
            .tabItem { Label(L10n.Main.tabFavorites, systemImage: "star.fill") }
            .tag(RescueTab.favorites)

            AboutView()
                .tabItem { Label(L10n.Main.tabAbout, systemImage: "info.circle") }
                .tag(RescueTab.about)
        }
        .onChange(of: autoSpeakEnglish) { _, value in
            guard session.autoSpeakEnglish != value else { return }
            session.autoSpeakEnglish = value
        }
        .onAppear {
            let stored = session.autoSpeakEnglish
            if autoSpeakEnglish != stored {
                autoSpeakEnglish = stored
            }
        }
    }

    private var mainView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    statusBanner
                    englishResult
                    holdToSpeakButton
                    mainControlsRow
                    failureActions
                    recognizedPolishSection
                    actionButtons
                    quickPhrasesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("TalkRescue")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        launchCoordinator.requestRescueMode(source: .inApp, autoListen: true)
                    } label: {
                        Label(L10n.Main.rescueToolbar, systemImage: "bolt.fill")
                    }
                    .accessibilityLabel(L10n.Main.rescueToolbar)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var statusBanner: some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(currentStatusColor)
                .frame(width: 11, height: 11)

            Text(session.statusLabel())
                .font(.body.weight(.semibold))
                .foregroundStyle(currentStatusColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.cardPadding)
        .padding(.vertical, 16)
        .background(statusBannerBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius)
                .strokeBorder(currentStatusColor.opacity(isActiveState ? 0.35 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius))
        .shadow(color: currentStatusColor.opacity(isActiveState ? 0.10 : 0), radius: 14, y: 4)
        .animation(.easeInOut(duration: 0.22), value: session.statusLabel())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(session.statusLabel())
        .accessibilityIdentifier("statusBanner")
    }

    private var statusBannerBackground: Color {
        if session.isListeningReady { return AppTheme.listeningBackground }
        if session.isPreparingToListen { return AppTheme.preparingBackground }
        if session.isTranslating { return AppTheme.translatingBackground }
        if session.isSpeaking { return AppTheme.successBackground }
        if session.showTranslationError || session.speechManager.errorMessage != nil {
            return AppTheme.listeningBackground
        }
        return AppTheme.quietSurfaceAlt
    }

    private var isActiveState: Bool {
        session.isListeningReady || session.isPreparingToListen || session.isTranslating || session.isSpeaking
    }

    private var englishResult: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Main.englishLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(session.englishText.isEmpty ? L10n.Main.englishPlaceholder : session.englishText)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(session.englishText.isEmpty ? .secondary : .primary)
                .minimumScaleFactor(0.5)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.quietSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
        .shadow(color: AppTheme.elevatedShadow, radius: 12, y: 3)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: session.englishText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.Main.englishLabel). \(session.englishText.isEmpty ? L10n.Main.englishPlaceholder : session.englishText)")
    }

    private var holdToSpeakButton: some View {
        Button {
        } label: {
            VStack(spacing: 14) {
                Image(systemName: session.isListeningReady ? "mic.circle.fill" : "mic.circle")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.hierarchical)

                Text(holdButtonLabel)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 168)
            .background(holdButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: holdButtonColor.opacity(0.20), radius: 18, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHoldingRecordButton, !session.isListeningReady, !session.isPreparingToListen, !session.isTranslating else { return }
                    isHoldingRecordButton = true
                    Task { await session.beginRecording() }
                }
                .onEnded { _ in
                    guard isHoldingRecordButton else { return }
                    isHoldingRecordButton = false
                    if session.isPreparingToListen {
                        session.cancelActiveWork()
                        return
                    }
                    guard session.isListeningReady else { return }
                    session.finishRecordingAndTranslate(source: "recording")
                }
        )
        .disabled(session.isTranslating)
        .opacity(session.isTranslating ? 0.85 : 1)
        .animation(.easeInOut(duration: 0.22), value: session.isPreparingToListen)
        .animation(.easeInOut(duration: 0.22), value: session.isListeningReady)
        .accessibilityLabel(holdButtonLabel)
        .accessibilityHint(L10n.Main.holdToSpeak)
        .accessibilityAddTraits(session.isListeningReady ? .isSelected : [])
    }

    private var mainControlsRow: some View {
        Toggle(L10n.Main.autoSpeak, isOn: $autoSpeakEnglish)
            .font(.body.weight(.medium))
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var failureActions: some View {
        if !session.lastPolishText.isEmpty {
            HStack(spacing: 12) {
                Button(L10n.Main.retry) { session.retryTranslation() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(minHeight: AppTheme.minTapTarget)
                    .disabled(session.isTranslating || session.retryPolishText == nil)

                Button(L10n.Main.clear) { session.clearCurrentResult() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: AppTheme.minTapTarget)
                    .disabled(session.isTranslating)
            }
        }
    }

    private var recognizedPolishSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Main.recognizedPolish)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(session.speechManager.recognizedText.isEmpty ? L10n.Main.nothingRecognized : session.speechManager.recognizedText)
                .font(.body)
                .foregroundStyle(session.speechManager.recognizedText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.quietSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            compactActionButton(title: L10n.Main.speak, systemImage: "speaker.wave.2.fill") {
                session.speakEnglish()
            }

            compactActionButton(title: L10n.Main.copy, systemImage: "doc.on.doc") {
                UIPasteboard.general.string = session.englishText
                session.statusMessage = L10n.Main.copied
                session.speechManager.clearError()
                session.showTranslationError = false
            }

            compactActionButton(title: L10n.Main.save, systemImage: "star") {
                phraseStore.saveFavorite(polishText: session.speechManager.recognizedText, englishText: session.englishText)
                session.statusMessage = L10n.Main.savedToFavorites
                session.speechManager.clearError()
                session.showTranslationError = false
            }

            compactActionButton(title: L10n.Main.clear, systemImage: "xmark") {
                session.clearCurrentResult()
            }
        }
        .disabled(session.englishText.isEmpty && session.speechManager.recognizedText.isEmpty && !session.showTranslationError)
    }

    private func compactActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: AppTheme.minTapTarget)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private var quickPhrasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Main.quickPhrases)
                .font(.headline)

            ForEach(quickPhrases, id: \.self) { phrase in
                Button {
                    session.cancelActiveWork()
                    isHoldingRecordButton = false
                    session.englishText = phrase
                    session.speechManager.clearRecognizedText()
                    session.statusMessage = L10n.Main.ready
                    session.speechManager.clearError()
                    session.showTranslationError = false
                    session.lastPolishText = ""
                    session.speakEnglish()
                } label: {
                    HStack {
                        Text(phrase)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 12)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.micIdle)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.micIdle.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .padding(AppTheme.cardPadding)
                    .background(AppTheme.quietSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .strokeBorder(AppTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.elevatedShadow.opacity(0.7), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(phrase). \(L10n.Main.speak)")
            }
        }
    }

    private enum PhraseListStyle {
        case history
        case favorites
    }

    private func phraseListView(
        title: String,
        phrases: [Phrase],
        emptyText: String,
        style: PhraseListStyle,
        allowsDelete: Bool = false
    ) -> some View {
        NavigationStack {
            Group {
                if phrases.isEmpty {
                    ContentUnavailableView(title, systemImage: "text.bubble", description: Text(emptyText))
                } else if style == .history {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(phrases) { phrase in
                                Button {
                                    selectPhrase(phrase)
                                } label: {
                                    PhraseCardRow(phrase: phrase)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(phrases) { phrase in
                            Button {
                                selectPhrase(phrase)
                            } label: {
                                PhraseCardRow(phrase: phrase, showsTimestamp: false)
                                    .listRowInsets(EdgeInsets())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            guard allowsDelete else { return }
                            offsets.map { phrases[$0] }.forEach(phraseStore.removeFavorite)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle(title)
        }
    }

    private func selectPhrase(_ phrase: Phrase) {
        session.cancelActiveWork()
        isHoldingRecordButton = false
        session.englishText = phrase.englishText
        session.speechManager.setRecognizedTextForDisplay(phrase.polishText)
        session.statusMessage = L10n.Main.ready
        session.speechManager.clearError()
        session.showTranslationError = false
        session.lastPolishText = phrase.polishText
        selectedTab = .main
    }

    private var holdButtonLabel: String {
        if session.isPreparingToListen { return L10n.Rescue.preparingMic }
        if session.isListeningReady { return L10n.Main.releaseToTranslate }
        return L10n.Main.holdToSpeak
    }

    private var holdButtonColor: Color {
        if session.isListeningReady { return AppTheme.micListening }
        if session.isPreparingToListen { return AppTheme.micPreparing }
        return AppTheme.micIdle
    }

    private var holdButtonBackground: LinearGradient {
        LinearGradient(
            colors: [
                holdButtonColor.opacity(0.94),
                holdButtonGradientBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var holdButtonGradientBottom: Color {
        if session.isListeningReady { return Color(red: 0.56, green: 0.20, blue: 0.26) }
        if session.isPreparingToListen { return Color(red: 0.64, green: 0.36, blue: 0.12) }
        return Color(red: 0.10, green: 0.25, blue: 0.48)
    }

    private var currentStatusColor: Color {
        if session.statusMessage == L10n.Main.noSpeechDetected { return AppTheme.idle }
        if session.isListeningReady { return AppTheme.listening }
        if session.isPreparingToListen { return AppTheme.preparing }
        if session.isTranslating { return AppTheme.translating }
        if session.isSpeaking { return AppTheme.success }
        if session.speechManager.errorMessage != nil || session.showTranslationError { return AppTheme.listening }
        if !session.englishText.isEmpty { return AppTheme.success }
        return AppTheme.idle
    }
}

private enum RescueTab {
    case main
    case history
    case favorites
    case about
}

#if DEBUG
#Preview {
    let phraseStore = PhraseStore()
    ContentView(session: RescueSession(phraseStore: phraseStore))
        .environmentObject(phraseStore)
        .environmentObject(RescueLaunchCoordinator.shared)
}
#endif
