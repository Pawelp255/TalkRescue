import Foundation

/// Privacy-friendly counters stored only in UserDefaults on device.
enum LocalUsageAnalytics {
    enum TranslationSource {
        case cache
        case apple
        case proxy
    }

    struct Snapshot: Equatable {
        let totalTranslations: Int
        let mostUsedLanguageLabel: String
        let rescueModeUses: Int
        let cacheHits: Int
        let proxyTranslations: Int
        let shortcutRescueLaunches: Int
        let appLaunchCount: Int
        let averageProxyDurationMs: Int?
    }

    private enum Key {
        static let prefix = "analytics."
        static let firstLaunchDate = prefix + "firstLaunchDate"
        static let appLaunchCount = prefix + "appLaunchCount"
        static let translationCountTotal = prefix + "translationCountTotal"
        static let translationCountByProfile = prefix + "translationCountByProfile"
        static let rescueModeUsageCount = prefix + "rescueModeUsageCount"
        static let shortcutRescueLaunchCount = prefix + "shortcutRescueLaunchCount"
        static let cacheHitCount = prefix + "cacheHitCount"
        static let proxyTranslationCount = prefix + "proxyTranslationCount"
        static let proxyDurationTotalMs = prefix + "proxyDurationTotalMs"
        static let proxyDurationSampleCount = prefix + "proxyDurationSampleCount"
        static let successfulTranslationCount = prefix + "successfulTranslationCount"
        static let ratingPromptRequested = prefix + "ratingPromptRequested"
    }

    static func recordAppLaunch() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Key.firstLaunchDate) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: Key.firstLaunchDate)
        }
        defaults.set(defaults.integer(forKey: Key.appLaunchCount) + 1, forKey: Key.appLaunchCount)
    }

    static func recordRescueModeUse() {
        increment(Key.rescueModeUsageCount)
    }

    static func recordShortcutRescueLaunch() {
        increment(Key.shortcutRescueLaunchCount)
    }

    static func recordTranslationSuccess(
        profileId: String,
        source: TranslationSource,
        durationMs: Int? = nil
    ) {
        increment(Key.translationCountTotal)
        increment(Key.successfulTranslationCount)
        incrementProfileCount(profileId: profileId)

        switch source {
        case .cache:
            increment(Key.cacheHitCount)
        case .apple:
            break
        case .proxy:
            increment(Key.proxyTranslationCount)
            if let durationMs, durationMs >= 0 {
                let defaults = UserDefaults.standard
                let total = defaults.integer(forKey: Key.proxyDurationTotalMs) + durationMs
                let samples = defaults.integer(forKey: Key.proxyDurationSampleCount) + 1
                defaults.set(total, forKey: Key.proxyDurationTotalMs)
                defaults.set(samples, forKey: Key.proxyDurationSampleCount)
            }
        }
    }

    static var shouldOfferRatingPrompt: Bool {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Key.ratingPromptRequested) else { return false }

        let successfulCount = defaults.integer(forKey: Key.successfulTranslationCount)
        if successfulCount >= 20 { return true }

        guard let firstLaunch = firstLaunchDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        return days >= 7
    }

    static func markRatingPromptRequested() {
        UserDefaults.standard.set(true, forKey: Key.ratingPromptRequested)
    }

    static func snapshot() -> Snapshot {
        let defaults = UserDefaults.standard
        let profileCounts = loadProfileCounts()
        let mostUsedProfileId = profileCounts.max(by: { $0.value < $1.value })?.key
        let mostUsedLabel = mostUsedProfileId
            .flatMap { LanguageProfile.profile(id: $0)?.shortLabel }
            ?? "—"

        let proxySamples = defaults.integer(forKey: Key.proxyDurationSampleCount)
        let proxyTotalMs = defaults.integer(forKey: Key.proxyDurationTotalMs)
        let averageMs = proxySamples > 0 ? proxyTotalMs / proxySamples : nil

        return Snapshot(
            totalTranslations: defaults.integer(forKey: Key.translationCountTotal),
            mostUsedLanguageLabel: mostUsedLabel,
            rescueModeUses: defaults.integer(forKey: Key.rescueModeUsageCount),
            cacheHits: defaults.integer(forKey: Key.cacheHitCount),
            proxyTranslations: defaults.integer(forKey: Key.proxyTranslationCount),
            shortcutRescueLaunches: defaults.integer(forKey: Key.shortcutRescueLaunchCount),
            appLaunchCount: defaults.integer(forKey: Key.appLaunchCount),
            averageProxyDurationMs: averageMs
        )
    }

    private static var firstLaunchDate: Date? {
        let interval = UserDefaults.standard.double(forKey: Key.firstLaunchDate)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private static func increment(_ key: String) {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private static func incrementProfileCount(profileId: String) {
        var counts = loadProfileCounts()
        counts[profileId, default: 0] += 1
        saveProfileCounts(counts)
    }

    private static func loadProfileCounts() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: Key.translationCountByProfile),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveProfileCounts(_ counts: [String: Int]) {
        guard let data = try? JSONEncoder().encode(counts) else { return }
        UserDefaults.standard.set(data, forKey: Key.translationCountByProfile)
    }
}
