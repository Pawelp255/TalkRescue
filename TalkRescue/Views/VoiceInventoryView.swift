#if DEBUG

import AVFoundation
import SwiftUI
import UIKit

enum VoiceInventoryFilter: String, CaseIterable, Identifiable {
    case all = "ALL"
    case en = "EN"
    case de = "DE"
    case sv = "SV"
    case es = "ES"

    var id: String { rawValue }

    func matches(_ voice: AVSpeechSynthesisVoice) -> Bool {
        switch self {
        case .all:
            return true
        case .en:
            return voice.language.hasPrefix("en")
        case .de:
            return voice.language.hasPrefix("de")
        case .sv:
            return voice.language.hasPrefix("sv")
        case .es:
            return voice.language.hasPrefix("es")
        }
    }
}

struct VoiceInventoryRow: Identifiable, Equatable {
    let id: String
    let name: String
    let identifier: String
    let language: String
    let qualityLabel: String
    let isTalkRescueSelected: Bool
}

enum VoiceInventoryLoader {
    static func loadRows(
        filter: VoiceInventoryFilter,
        selectedVoiceIdentifier: String?
    ) -> [VoiceInventoryRow] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { filter.matches($0) }
            .map { voice in
                VoiceInventoryRow(
                    id: voice.identifier,
                    name: voice.name,
                    identifier: voice.identifier,
                    language: voice.language,
                    qualityLabel: qualityLabel(for: voice),
                    isTalkRescueSelected: voice.identifier == selectedVoiceIdentifier
                )
            }
            .sorted { lhs, rhs in
                if lhs.language == rhs.language {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.language.localizedCaseInsensitiveCompare(rhs.language) == .orderedAscending
            }
    }

    static func qualityLabel(for voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium:
            return "premium"
        case .enhanced:
            return "enhanced"
        case .default:
            if voice.identifier.contains("super-compact") || voice.identifier.contains("compact") {
                return "compact"
            }
            return "default"
        @unknown default:
            return "unknown"
        }
    }

    static func tierLabel(_ tier: VoiceQualityTier) -> String {
        tier.displayLabel.lowercased()
    }

    static func buildReport(
        profileLabel: String,
        voiceLanguage: String,
        selectedVoice: AVSpeechSynthesisVoice?,
        selectedTier: VoiceQualityTier,
        filter: VoiceInventoryFilter,
        rows: [VoiceInventoryRow]
    ) -> String {
        var lines: [String] = []
        lines.append("TalkRescue Voice Inventory Report")
        lines.append("Generated: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("")
        lines.append("TalkRescue selection")
        lines.append("  Profile: \(profileLabel)")
        lines.append("  TTS language: \(voiceLanguage)")
        lines.append("  Selected voice: \(selectedVoice?.name ?? "—")")
        lines.append("  Selected identifier: \(selectedVoice?.identifier ?? "—")")
        lines.append("  Selected tier: \(tierLabel(selectedTier))")
        lines.append("")
        lines.append("Filter: \(filter.rawValue)")
        lines.append("Visible voices: \(rows.count)")
        lines.append("")

        for row in rows {
            let selected = row.isTalkRescueSelected ? " [SELECTED]" : ""
            lines.append("\(row.name)\(selected)")
            lines.append("  \(row.language)")
            lines.append("  \(row.qualityLabel)")
            lines.append("  \(row.identifier)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}

struct VoiceInventoryView: View {
    @EnvironmentObject private var profileStore: LanguageProfileStore

    @State private var filter: VoiceInventoryFilter = .all
    @State private var rows: [VoiceInventoryRow] = []
    @State private var showCopiedConfirmation = false

    private var profile: LanguageProfile { profileStore.selectedProfile }
    private var voiceLanguage: String { profile.ttsVoiceLanguage }
    private var selectedVoice: AVSpeechSynthesisVoice? {
        TTSService.resolvedVoice(for: voiceLanguage)
    }
    private var selectedTier: VoiceQualityTier {
        TTSService.resolvedTier(for: voiceLanguage)
    }

    var body: some View {
        List {
            Section("TalkRescue selection") {
                LabeledContent("Profile", value: profile.shortLabel)
                LabeledContent("TTS language", value: voiceLanguage)
                LabeledContent("Selected voice", value: selectedVoice?.name ?? "—")
                LabeledContent("Tier", value: VoiceInventoryLoader.tierLabel(selectedTier))
                if let identifier = selectedVoice?.identifier {
                    Text(identifier)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(VoiceInventoryFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: filter) { _, _ in
                    refresh()
                }

                HStack {
                    Button("Refresh") {
                        refresh()
                    }
                    Spacer()
                    Button("Copy Report") {
                        copyReport()
                    }
                }
            }

            Section("AVSpeechSynthesisVoice.speechVoices() (\(rows.count))") {
                if rows.isEmpty {
                    Text("No voices match this filter.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows) { row in
                        voiceRow(row)
                    }
                }
            }
        }
        .navigationTitle("Voice Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refresh()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: AVSpeechSynthesizer.availableVoicesDidChangeNotification
            )
        ) { _ in
            refresh()
        }
        .alert("Copied", isPresented: $showCopiedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Voice inventory report copied to clipboard.")
        }
    }

    private func voiceRow(_ row: VoiceInventoryRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.name)
                    .font(.headline)
                if row.isTalkRescueSelected {
                    Text("SELECTED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            Text(row.language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(row.qualityLabel)
                .font(.caption)
                .foregroundStyle(qualityColor(row.qualityLabel))
            Text(row.identifier)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }

    private func qualityColor(_ quality: String) -> Color {
        switch quality {
        case "premium", "enhanced": return .green
        case "compact", "default": return .orange
        default: return .secondary
        }
    }

    private func refresh() {
        rows = VoiceInventoryLoader.loadRows(
            filter: filter,
            selectedVoiceIdentifier: selectedVoice?.identifier
        )
    }

    private func copyReport() {
        let report = VoiceInventoryLoader.buildReport(
            profileLabel: profile.shortLabel,
            voiceLanguage: voiceLanguage,
            selectedVoice: selectedVoice,
            selectedTier: selectedTier,
            filter: filter,
            rows: rows
        )
        UIPasteboard.general.string = report
        showCopiedConfirmation = true
    }
}

#Preview {
    NavigationStack {
        VoiceInventoryView()
            .environmentObject(LanguageProfileStore())
    }
}

#endif
