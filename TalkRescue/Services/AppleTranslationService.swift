import Foundation
import os

/// Apple on-device translation — iOS 18+, installed models only (no download UI).
enum AppleTranslationService {
    private static let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "AppleTranslation")

    /// Profiles confirmed for Apple Translation on device spike (pl-sv excluded: unsupported).
    private static let eligibleProfileIDs: Set<String> = ["pl-en", "pl-de", "pl-es"]

    static func isProfileEligible(_ profile: LanguageProfile) -> Bool {
        eligibleProfileIDs.contains(profile.id)
    }

    static func sourceLanguage(for profile: LanguageProfile) -> String {
        profile.sourceLocaleIdentifier.split(separator: "-").first.map(String.init) ?? "pl"
    }

    static func targetLanguage(for profile: LanguageProfile) -> String {
        profile.targetLocaleIdentifier.split(separator: "-").first.map(String.init)
            ?? profile.targetLocaleIdentifier
    }

    /// Attempt on-device translation when models are **installed**. Never triggers download UI.
    @available(iOS 18, *)
    static func translateIfInstalled(
        _ text: String,
        profile: LanguageProfile
    ) async throws -> (translation: String, durationMs: Int)? {
        guard isProfileEligible(profile) else {
            logger.info("Apple translation skipped — profile not eligible profile=\(profile.id, privacy: .public)")
            return nil
        }

        return try await AppleTranslationService_iOS18.translateIfInstalled(text, profile: profile)
    }
}

#if canImport(Translation)
import Translation

@available(iOS 18, *)
private enum AppleTranslationService_iOS18 {
    private static let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "AppleTranslation")

    static func translateIfInstalled(
        _ text: String,
        profile: LanguageProfile
    ) async throws -> (translation: String, durationMs: Int)? {
        let source = Locale.Language(identifier: AppleTranslationService.sourceLanguage(for: profile))
        let target = Locale.Language(identifier: AppleTranslationService.targetLanguage(for: profile))
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)

        guard status == .installed else {
            logger.info(
                "Apple translation skipped — not installed profile=\(profile.id, privacy: .public) status=\(String(describing: status), privacy: .public)"
            )
            return nil
        }

        let started = Date()
        let translation = try await AppleTranslationBridge.shared.translate(
            text: text,
            source: source,
            target: target
        )
        let durationMs = Int(Date().timeIntervalSince(started) * 1000)
        logger.info(
            "Translation route: apple profile=\(profile.id, privacy: .public) durationMs=\(durationMs, privacy: .public)"
        )
        return (translation, durationMs)
    }
}

#else

@available(iOS 18, *)
private enum AppleTranslationService_iOS18 {
    static func translateIfInstalled(
        _ text: String,
        profile: LanguageProfile
    ) async throws -> (translation: String, durationMs: Int)? {
        nil
    }
}

#endif
