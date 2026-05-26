import SwiftUI
import os

struct RootView: View {
    @EnvironmentObject private var phraseStore: PhraseStore
    @EnvironmentObject private var launchCoordinator: RescueLaunchCoordinator
    @EnvironmentObject private var profileStore: LanguageProfileStore

    @StateObject private var rescueSession: RescueSession

    @Environment(\.scenePhase) private var scenePhase
    @State private var didLogRootAppear = false

    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "RootView")

    init(phraseStore: PhraseStore, profileStore: LanguageProfileStore) {
        _rescueSession = StateObject(wrappedValue: RescueSession(phraseStore: phraseStore, profileStore: profileStore))
    }

    private var shouldBlockUIWithOnboarding: Bool {
        !launchCoordinator.showRescueMode && !profileStore.languageOnboardingCompleted
    }

    var body: some View {
        ZStack {
            Group {
                if launchCoordinator.showRescueMode {
                    RescueModeView(session: rescueSession)
                        .environmentObject(launchCoordinator)
                } else {
                    ContentView(session: rescueSession)
                        .environmentObject(rescueSession)
                }
            }

            if shouldBlockUIWithOnboarding {
                LanguageOnboardingView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .transaction { transaction in
            if launchCoordinator.launchedDirectlyToRescue {
                transaction.disablesAnimations = true
                transaction.animation = nil
            }
        }
        .onAppear {
            if !didLogRootAppear {
                didLogRootAppear = true
                LaunchMetrics.logSinceLaunch("Cold start to root")
            }
            launchCoordinator.restorePendingLaunchIfNeeded()
            if launchCoordinator.showRescueMode {
                launchCoordinator.logRescuePresentationIfNeeded()
            }
        }
        .onChange(of: launchCoordinator.rescueRequestID) { _, requestID in
            logger.info("RootView observed rescue request id=\(requestID, privacy: .public)")
        }
        .onChange(of: launchCoordinator.showRescueMode) { _, showing in
            if showing {
                launchCoordinator.logRescuePresentationIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                launchCoordinator.restorePendingLaunchIfNeeded()
            case .background:
                rescueSession.handleBackground()
            default:
                break
            }
        }
    }
}
