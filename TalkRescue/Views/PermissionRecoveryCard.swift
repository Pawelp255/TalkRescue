import SwiftUI
import UIKit

/// Guides users to Settings when microphone or speech recognition was denied.
struct PermissionRecoveryCard: View {
    @ObservedObject var speechManager: SpeechManager
    var prefersDarkAppearance: Bool = false
    var onRecheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mic.slash.fill")
                    .font(.title2)
                    .foregroundStyle(emphasisColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Permissions.recoveryTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(titleColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.Permissions.recoveryDescription)
                        .font(.subheadline)
                        .foregroundStyle(descriptionColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                Button {
                    openSettings()
                } label: {
                    Text(L10n.Permissions.openSettings)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(prefersDarkAppearance ? AppTheme.rescueReady : nil)

                Button {
                    onRecheck()
                } label: {
                    Text(L10n.Permissions.recheck)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapTarget)
                }
                .buttonStyle(.bordered)
                .tint(prefersDarkAppearance ? .white : nil)
            }
        }
        .padding(AppTheme.cardPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.bannerCornerRadius)
                .strokeBorder(emphasisColor.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("permissionRecoveryCard")
    }

    private var emphasisColor: Color {
        prefersDarkAppearance
            ? Color(red: 0.95, green: 0.45, blue: 0.45)
            : AppTheme.listening
    }

    private var titleColor: Color {
        prefersDarkAppearance ? .white : .primary
    }

    private var descriptionColor: Color {
        prefersDarkAppearance ? .white.opacity(0.75) : .secondary
    }

    private var cardBackground: Color {
        prefersDarkAppearance
            ? Color.white.opacity(0.08)
            : AppTheme.listeningBackground
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#if DEBUG
#Preview {
    PermissionRecoveryCard(
        speechManager: SpeechManager(),
        onRecheck: {}
    )
    .padding()
}
#endif
