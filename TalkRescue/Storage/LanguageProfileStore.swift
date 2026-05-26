import Combine
import Foundation

/// Persists the active rescue language profile for Main and Rescue Mode.
@MainActor
final class LanguageProfileStore: ObservableObject {
    static let userDefaultsKey = "selectedLanguageProfileID"
    private static let onboardingCompletedKey = "languageOnboarding.completed"
    private static let migrationMarkKey = "languageOnboarding.passB_migration_v1"

    @Published private(set) var selectedProfile: LanguageProfile
    @Published private(set) var languageOnboardingCompleted: Bool

    init() {
        LanguageProfileStore.runOldInstallMigrationIfNeeded()
        selectedProfile = LanguageProfileStore.loadStoredProfile()
        languageOnboardingCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
    }

    private static func loadStoredProfile() -> LanguageProfile {
        let storedID = UserDefaults.standard.string(forKey: Self.userDefaultsKey)
        return LanguageProfile.profile(id: storedID ?? "") ?? .default
    }

    /// One-time: existing installs skip forced onboarding when they already have phrase data or explicit profile stored.
    private static func runOldInstallMigrationIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.migrationMarkKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.migrationMarkKey)

        let hasHistoryBucket = UserDefaults.standard.data(forKey: "talkRescue.history") != nil
        let hasFavoritesBucket = UserDefaults.standard.data(forKey: "talkRescue.favorites") != nil
        let hasExplicitProfile = UserDefaults.standard.string(forKey: Self.userDefaultsKey) != nil
        if hasHistoryBucket || hasFavoritesBucket || hasExplicitProfile {
            UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        }
    }

    func select(_ profile: LanguageProfile) {
        if profile != selectedProfile {
            selectedProfile = profile
            UserDefaults.standard.set(profile.id, forKey: Self.userDefaultsKey)
        }
        if !languageOnboardingCompleted {
            UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
            languageOnboardingCompleted = true
        }
    }

    /// First-launch onboarding: persists choice and hides onboarding permanently.
    func completeLanguageOnboarding(with profile: LanguageProfile) {
        select(profile)
    }
}
