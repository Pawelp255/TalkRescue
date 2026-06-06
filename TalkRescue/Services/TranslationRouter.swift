import Foundation
import os

enum TranslationRoute: String {
    case cache
    case apple
    case supabase
}

/// Cache → Apple Translation (installed) → Supabase proxy.
enum TranslationRouter {
    private static let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "TranslationRouter")

    struct Result {
        let translation: String
        let route: TranslationRoute
        let durationMs: Int
    }

    static func translate(
        _ text: String,
        profile: LanguageProfile,
        supabaseService: TranslationService
    ) async throws -> Result {
        if #available(iOS 18, *) {
            do {
                if let appleResult = try await AppleTranslationService.translateIfInstalled(text, profile: profile) {
                    return Result(
                        translation: appleResult.translation,
                        route: .apple,
                        durationMs: appleResult.durationMs
                    )
                }
            } catch {
                logger.error(
                    "Apple translation error — supabase fallback profile=\(profile.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
                )
            }
        }

        logger.info("Translation route: supabase fallback profile=\(profile.id, privacy: .public)")
        let started = Date()
        let translation = try await supabaseService.translate(text, profile: profile)
        let durationMs = Int(Date().timeIntervalSince(started) * 1000)
        logger.info(
            "Translation route: supabase profile=\(profile.id, privacy: .public) durationMs=\(durationMs, privacy: .public)"
        )
        return Result(translation: translation, route: .supabase, durationMs: durationMs)
    }
}
