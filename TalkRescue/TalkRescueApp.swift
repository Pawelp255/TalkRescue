import SwiftUI

@main
struct TalkRescueApp: App {
    @StateObject private var phraseStore = PhraseStore()
    @StateObject private var profileStore = LanguageProfileStore()
    @ObservedObject private var launchCoordinator = RescueLaunchCoordinator.shared

    var body: some Scene {
        WindowGroup {
            RootView(phraseStore: phraseStore, profileStore: profileStore)
                .environmentObject(phraseStore)
                .environmentObject(profileStore)
                .environmentObject(launchCoordinator)
        }
    }
}
