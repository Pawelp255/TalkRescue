import SwiftUI

/// Shared visual tokens for a calm, readable, App Store–ready UI.
enum AppTheme {
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 16
    static let bannerCornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let minTapTarget: CGFloat = 48
    static let hairline = Color.primary.opacity(0.08)
    static let darkHairline = Color.white.opacity(0.14)
    static let elevatedShadow = Color.black.opacity(0.08)

    /// Softer than system red for long listening sessions.
    static let listening = Color(red: 0.78, green: 0.32, blue: 0.36)
    static let listeningBackground = listening.opacity(0.10)

    static let preparing = Color.orange.opacity(0.88)
    static let preparingBackground = preparing.opacity(0.10)

    static let translating = Color(red: 0.85, green: 0.55, blue: 0.22)
    static let translatingBackground = translating.opacity(0.10)

    static let success = Color(red: 0.22, green: 0.62, blue: 0.42)
    static let successBackground = success.opacity(0.10)

    static let idle = Color.secondary
    static let idleBackground = Color(.secondarySystemGroupedBackground)
    static let quietSurface = Color(.systemBackground)
    static let quietSurfaceAlt = Color(.secondarySystemGroupedBackground)

    static let micIdle = Color(red: 0.17, green: 0.38, blue: 0.72)
    static let micPreparing = preparing
    static let micListening = listening

    static let rescueReady = Color(red: 0.35, green: 0.78, blue: 0.55)
    static let rescueRecording = Color(red: 0.45, green: 0.72, blue: 0.95)
    static let rescueSurface = Color.white.opacity(0.08)
    static let rescueSurfaceRaised = Color.white.opacity(0.12)
    static let rescueBackgroundTop = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let rescueBackgroundBottom = Color(red: 0.02, green: 0.025, blue: 0.035)
}
