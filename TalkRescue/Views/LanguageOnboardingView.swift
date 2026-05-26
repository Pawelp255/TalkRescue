import SwiftUI

/// Pass B: first-run language choice (skipped during Rescue Mode / Action Button).
struct LanguageOnboardingView: View {
    @EnvironmentObject private var profileStore: LanguageProfileStore

    @State private var choice: LanguageProfile = .polishToEnglish

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 36)

                VStack(spacing: 12) {
                    Text(L10n.LanguageUX.onboardingTitle)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(L10n.LanguageUX.onboardingSubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    ForEach(LanguageProfile.all) { profile in
                        onboardingOption(profile)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(L10n.LanguageUX.onboardingCTA) {
                    profileStore.completeLanguageOnboarding(with: choice)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: AppTheme.minTapTarget)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .interactiveDismissDisabled(true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("languageOnboarding")
    }

    private func onboardingOption(_ profile: LanguageProfile) -> some View {
        let selected = profile.id == choice.id
        return Button {
            choice = profile
        } label: {
            HStack(spacing: 14) {
                Text(onboardingCaption(for: profile))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
            }
            .padding(.horizontal, AppTheme.cardPadding)
            .padding(.vertical, 20)
            .frame(minHeight: AppTheme.minTapTarget + 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(selected ? Color.accentColor.opacity(0.45) : AppTheme.hairline, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(onboardingCaption(for: profile))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func onboardingCaption(for profile: LanguageProfile) -> String {
        switch profile.id {
        case LanguageProfile.polishToEnglish.id: return L10n.LanguageUX.onboardingOptionEnglish
        case LanguageProfile.polishToSwedish.id: return L10n.LanguageUX.onboardingOptionSwedish
        case LanguageProfile.polishToSpanish.id: return L10n.LanguageUX.onboardingOptionSpanish
        default: return profile.displayTitle
        }
    }
}

#if DEBUG
#Preview {
    LanguageOnboardingView()
        .environmentObject(LanguageProfileStore())
}
#endif
