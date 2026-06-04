import SwiftUI

// MARK: - Compact chip → sheet picker

/// Small chip (e.g. `Ang. ▾`); avoids accidental segmented switching and wrapping on SE-sized screens.
struct LanguageChipControl: View {
    @ObservedObject var profileStore: LanguageProfileStore
    var prefersDarkAppearance: Bool = false

    @State private var showSheet = false

    private var profile: LanguageProfile { profileStore.selectedProfile }

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 5) {
                Text(profile.chipCompactLabel)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .opacity(0.85)
            }
            .foregroundStyle(prefersDarkAppearance ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: AppTheme.minTapTarget)
            .background(
                Capsule()
                    .fill(prefersDarkAppearance ? Color.white.opacity(0.12) : Color(.secondarySystemFill))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        prefersDarkAppearance ? Color.white.opacity(0.28) : Color.secondary.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(L10n.LanguageUX.chipAccessibilityPrefix) \(profile.shortLabel)")
        .accessibilityHint(L10n.LanguageUX.chipAccessibilityHint)
        .accessibilityIdentifier("languageChip")
        .sheet(isPresented: $showSheet) {
            LanguageSelectionSheet(
                profileStore: profileStore,
                prefersDarkAppearance: prefersDarkAppearance
            )
            .presentationDragIndicator(.visible)
        }
    }
}

/// Full list of profiles for changing language (onboarding picks separately).
struct LanguageSelectionSheet: View {
    @ObservedObject var profileStore: LanguageProfileStore
    var prefersDarkAppearance: Bool

    @Environment(\.dismiss) private var dismiss

    private var tint: Color {
        prefersDarkAppearance ? AppTheme.rescueReady : Color.accentColor
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.LanguageUX.sheetExplainer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 14)

                    VStack(spacing: 12) {
                        ForEach(LanguageProfile.all) { profile in
                            languageRow(profile)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .background(prefersDarkAppearance ? Color(red: 0.09, green: 0.10, blue: 0.14) : Color(.systemGroupedBackground))
            .navigationTitle(L10n.LanguageUX.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(prefersDarkAppearance ? Color(red: 0.09, green: 0.10, blue: 0.14).opacity(0.95) : Color(.systemGroupedBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.LanguageUX.sheetDone) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .frame(minHeight: AppTheme.minTapTarget)
                }
            }
            .preferredColorScheme(prefersDarkAppearance ? .dark : nil)
        }
    }

    private func languageRow(_ profile: LanguageProfile) -> some View {
        let selected = profile.id == profileStore.selectedProfile.id
        return Button {
            profileStore.select(profile)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(prefersDarkAppearance ? .white : .primary)
                        .multilineTextAlignment(.leading)
                    Text(profile.quickPhrases.first ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 12)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, AppTheme.cardPadding)
            .padding(.vertical, 18)
            .frame(minHeight: AppTheme.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(prefersDarkAppearance ? Color.white.opacity(0.07) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(selected ? tint.opacity(0.45) : AppTheme.hairline, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.displayTitle)\(selected ? L10n.LanguageUX.selectedSuffix : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("Chip") {
    LanguageChipControl(profileStore: LanguageProfileStore())
        .padding()
}

#Preview("Sheet") {
    LanguageSelectionSheet(profileStore: LanguageProfileStore(), prefersDarkAppearance: false)
}
#endif
