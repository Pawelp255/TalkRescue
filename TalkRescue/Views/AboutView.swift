import AVFoundation
import SwiftUI
import UIKit

struct AboutView: View {
    @EnvironmentObject private var profileStore: LanguageProfileStore

    @AppStorage(VoicePlaybackStyle.userDefaultsKey) private var voicePlaybackStyle = VoicePlaybackStyle.natural.rawValue
    @State private var showVoiceInstructions = false
    @State private var voicesRevision = 0
    @State private var usageStats = LocalUsageAnalytics.snapshot()
    @State private var showFeedbackUnavailableAlert = false

    var body: some View {
        NavigationStack {
            List {
                if shouldShowEnhancedVoiceCard {
                    Section {
                        enhancedVoiceCard
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section(L10n.About.voiceSection) {
                    voiceSettingsSection
                }

                Section(L10n.UsageStats.sectionTitle) {
                    LabeledContent(L10n.UsageStats.totalTranslations, value: "\(usageStats.totalTranslations)")
                    LabeledContent(L10n.UsageStats.mostUsedLanguage, value: usageStats.mostUsedLanguageLabel)
                    LabeledContent(L10n.UsageStats.rescueUses, value: "\(usageStats.rescueModeUses)")
                    LabeledContent(L10n.UsageStats.cacheHits, value: "\(usageStats.cacheHits)")
                    Text(L10n.UsageStats.localOnlyNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(L10n.About.feedbackSection) {
                    Button(L10n.UsageStats.sendFeedback) {
                        openFeedbackEmail()
                    }
                }

                Section(L10n.About.privacySection) {
                    Text(L10n.About.privacyBody)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(L10n.About.appSection) {
                    LabeledContent(L10n.About.nameLabel, value: "TalkRescue")
                    LabeledContent(L10n.About.versionLabel, value: appVersion)
                    LabeledContent(L10n.About.buildLabel, value: appBuild)
                }

                Section(L10n.About.quickLaunchSection) {
                    Text(L10n.About.quickLaunchBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(L10n.About.translationSection) {
                    Text(L10n.About.translationBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle(L10n.About.title)
            .onAppear {
                usageStats = LocalUsageAnalytics.snapshot()
            }
            .onReceive(NotificationCenter.default.publisher(for: AVSpeechSynthesizer.availableVoicesDidChangeNotification)) { _ in
                voicesRevision += 1
            }
            .alert(L10n.UsageStats.feedbackUnavailable, isPresented: $showFeedbackUnavailableAlert) {
                Button(L10n.Voice.instructionsDone, role: .cancel) {}
            }
            .sheet(isPresented: $showVoiceInstructions) {
                VoiceDownloadInstructionsSheet(languageName: profileStore.selectedProfile.shortLabel)
            }
        }
    }

    private var voiceSettingsSection: some View {
        Group {
            Picker(L10n.Voice.settingsSection, selection: $voicePlaybackStyle) {
                Text(L10n.Voice.styleStandard).tag(VoicePlaybackStyle.standard.rawValue)
                Text(L10n.Voice.styleNatural).tag(VoicePlaybackStyle.natural.rawValue)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.Voice.settingsSection)

            Text(voiceStyleHint)
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledContent(L10n.Voice.currentVoiceLabel, value: currentVoiceName)
            LabeledContent("Jakość", value: currentVoiceTierLabel)
        }
        .id(voicesRevision)
    }

    private var enhancedVoiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.Voice.enhancedAvailableCardTitle, systemImage: "waveform.badge.plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(L10n.Voice.enhancedCardBody(languageName: profileStore.selectedProfile.shortLabel))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(L10n.Voice.showInstructionsButton) {
                showVoiceInstructions = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var shouldShowEnhancedVoiceCard: Bool {
        _ = voicesRevision
        return TTSService.shouldSuggestEnhancedVoiceDownload(
            for: profileStore.selectedProfile.ttsVoiceLanguage
        )
    }

    private var voiceStyleHint: String {
        voicePlaybackStyle == VoicePlaybackStyle.natural.rawValue
            ? L10n.Voice.styleNaturalHint
            : L10n.Voice.styleStandardHint
    }

    private var currentVoiceName: String {
        _ = voicesRevision
        return TTSService.resolvedVoice(for: profileStore.selectedProfile.ttsVoiceLanguage)?.name ?? "—"
    }

    private var currentVoiceTierLabel: String {
        _ = voicesRevision
        switch TTSService.resolvedTier(for: profileStore.selectedProfile.ttsVoiceLanguage) {
        case .premium: return L10n.Voice.tierPremium
        case .enhanced: return L10n.Voice.tierEnhanced
        case .compact: return L10n.Voice.tierCompact
        case .unknown: return L10n.Voice.tierUnknown
        }
    }

    private func openFeedbackEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "pawelp255@gmail.com"
        components.queryItems = [URLQueryItem(name: "subject", value: "TalkRescue feedback")]

        guard let url = components.url else {
            showFeedbackUnavailableAlert = true
            return
        }

        #if os(iOS)
        UIApplication.shared.open(url) { accepted in
            if !accepted {
                showFeedbackUnavailableAlert = true
            }
        }
        #endif
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

private struct VoiceDownloadInstructionsSheet: View {
    let languageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(L10n.Voice.instructionsIntro)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Kroki") {
                    instructionRow(step: 1, title: L10n.Voice.instructionsStep1, systemImage: "gearshape")
                    instructionRow(step: 2, title: L10n.Voice.instructionsStep2, systemImage: "accessibility")
                    instructionRow(step: 3, title: L10n.Voice.instructionsStep3, systemImage: "text.bubble")
                    instructionRow(step: 4, title: L10n.Voice.instructionsStep4, systemImage: "person.wave.2")
                    instructionRow(
                        step: 5,
                        title: "\(L10n.Voice.instructionsStep5) (\(languageName))",
                        systemImage: "arrow.down.circle"
                    )
                }
            }
            .navigationTitle(L10n.Voice.instructionsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Voice.instructionsDone) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func instructionRow(step: Int, title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Text("\(step)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())
            Label(title, systemImage: systemImage)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    AboutView()
        .environmentObject(LanguageProfileStore())
}
#endif
