import StoreKit
import UIKit

/// Lightweight App Store rating prompt — system-controlled, no custom UI.
enum AppRatingPrompt {
    static func considerAfterSuccessfulTranslation() {
        guard LocalUsageAnalytics.shouldOfferRatingPrompt else { return }
        requestReviewIfPossible()
    }

    private static func requestReviewIfPossible() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            return
        }

        LocalUsageAnalytics.markRatingPromptRequested()
        SKStoreReviewController.requestReview(in: scene)
    }
}
