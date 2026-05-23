import SwiftUI

@main
struct TalkRescueApp: App {
    @StateObject private var phraseStore = PhraseStore()
    @ObservedObject private var launchCoordinator = RescueLaunchCoordinator.shared

    var body: some Scene {
        WindowGroup {
            RootView(phraseStore: phraseStore)
                .environmentObject(phraseStore)
                .environmentObject(launchCoordinator)
        }
    }
}
