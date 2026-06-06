import Foundation

// MARK: - Shared spike types (iOS 17+ safe, no Translation import)

enum AppleTranslationSpikeAvailability: String, CaseIterable, Identifiable {
    case notChecked
    case installed
    case needsDownload
    case unsupported
    case requiresIOS18
    case simulatorOnly

    var id: String { rawValue }

    var polishLabel: String {
        switch self {
        case .notChecked: return "Nie sprawdzono"
        case .installed: return "Zainstalowany"
        case .needsDownload: return "Wspierany — wymaga pobrania"
        case .unsupported: return "Niewspierany"
        case .requiresIOS18: return "Wymaga iOS 18"
        case .simulatorOnly: return "Tylko urządzenie fizyczne"
        }
    }
}

struct AppleTranslationSpikePhraseResult: Identifiable, Equatable {
    let id = UUID()
    let sourcePhrase: String
    let translatedText: String?
    let latencyMs: Int?
    let errorMessage: String?
}

struct AppleTranslationSpikePairReport: Identifiable, Equatable {
    let id: String
    let label: String
    let sourceCode: String
    let targetCode: String
    var availability: AppleTranslationSpikeAvailability
    var phraseResults: [AppleTranslationSpikePhraseResult]
    var averageLatencyMs: Int? {
        let samples = phraseResults.compactMap(\.latencyMs)
        guard !samples.isEmpty else { return nil }
        return samples.reduce(0, +) / samples.count
    }
}

enum AppleTranslationSpikeCatalog {
    static let pairs: [(id: String, label: String, source: String, target: String)] = [
        ("pl-en", "pl → en", "pl", "en"),
        ("pl-de", "pl → de", "pl", "de"),
        ("pl-sv", "pl → sv", "pl", "sv"),
        ("pl-es", "pl → es", "pl", "es"),
    ]

    static let samplePhrases = [
        "nie rozumiem",
        "potrzebuję pomocy",
        "gdzie jest dworzec?",
        "czy możesz mówić wolniej?",
    ]
}

#if DEBUG

import SwiftUI
import Translation

@available(iOS 18, *)
enum AppleTranslationSpikeRunner {
    static func baselineReports() -> [AppleTranslationSpikePairReport] {
        AppleTranslationSpikeCatalog.pairs.map { pair in
            AppleTranslationSpikePairReport(
                id: pair.id,
                label: pair.label,
                sourceCode: pair.source,
                targetCode: pair.target,
                availability: initialAvailability(),
                phraseResults: []
            )
        }
    }

    static func initialAvailability() -> AppleTranslationSpikeAvailability {
        #if targetEnvironment(simulator)
        return .simulatorOnly
        #else
        return .notChecked
        #endif
    }

    static func checkAvailability() async -> [AppleTranslationSpikePairReport] {
        #if targetEnvironment(simulator)
        return baselineReports()
        #else
        let availability = LanguageAvailability()
        var reports: [AppleTranslationSpikePairReport] = []
        for pair in AppleTranslationSpikeCatalog.pairs {
            let source = Locale.Language(identifier: pair.source)
            let target = Locale.Language(identifier: pair.target)
            let status = await availability.status(from: source, to: target)
            reports.append(
                AppleTranslationSpikePairReport(
                    id: pair.id,
                    label: pair.label,
                    sourceCode: pair.source,
                    targetCode: pair.target,
                    availability: mapAvailability(status),
                    phraseResults: []
                )
            )
        }
        return reports.sorted { $0.id < $1.id }
        #endif
    }

    private static func mapAvailability(_ status: LanguageAvailability.Status) -> AppleTranslationSpikeAvailability {
        switch status {
        case .installed:
            return .installed
        case .supported:
            return .needsDownload
        case .unsupported:
            return .unsupported
        @unknown default:
            return .unsupported
        }
    }
}

@available(iOS 18, *)
@MainActor
struct AppleTranslationSpikeView: View {
    @State private var reports: [AppleTranslationSpikePairReport] = []
    @State private var isRunning = false
    @State private var statusMessage = "Gotowy do testu na urządzeniu iOS 18+."
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var translationWork: SpikeTranslationWork?
    @State private var translationGeneration = 0
    @State private var pairTranslationContinuation: CheckedContinuation<Void, Never>?

    var body: some View {
        List {
            Section {
                Text("Izolowany test Apple Translation. Nie wpływa na tryb ratunkowy ani Supabase.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(statusMessage)
                    .font(.subheadline)
            }

            Section("Pary językowe") {
                ForEach(reports) { report in
                    pairSection(report)
                }
            }

            Section {
                Button(isRunning ? "Trwa test…" : "Uruchom test") {
                    Task { await runSpike() }
                }
                .disabled(isRunning)
            }
        }
        .navigationTitle("Apple Translation")
        .navigationBarTitleDisplayMode(.inline)
        .translationTask(translationConfig) { session in
            await performTranslationBatch(session: session)
        }
        .onAppear {
            if reports.isEmpty {
                if #available(iOS 18, *) {
                    reports = AppleTranslationSpikeRunner.baselineReports()
                }
            }
        }
    }

    @ViewBuilder
    private func pairSection(_ report: AppleTranslationSpikePairReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.label)
                    .font(.headline)
                Spacer()
                Text(report.availability.polishLabel)
                    .font(.caption)
                    .foregroundStyle(availabilityColor(report.availability))
            }

            if let average = report.averageLatencyMs {
                Text("Średnie opóźnienie: \(average) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !report.phraseResults.isEmpty {
                ForEach(report.phraseResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("„\(result.sourcePhrase)”")
                            .font(.caption)
                        if let translated = result.translatedText {
                            Text("→ \(translated)")
                                .font(.caption)
                            if let ms = result.latencyMs {
                                Text("\(ms) ms")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let error = result.errorMessage {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func availabilityColor(_ availability: AppleTranslationSpikeAvailability) -> Color {
        switch availability {
        case .installed: return .green
        case .needsDownload: return .orange
        case .notChecked: return .secondary
        case .unsupported, .requiresIOS18, .simulatorOnly: return .red
        }
    }

    private func runSpike() async {
        isRunning = true
        statusMessage = "Sprawdzam dostępność par…"
        translationConfig = nil
        translationWork = nil

        let availabilityReports = await AppleTranslationSpikeRunner.checkAvailability()
        reports = availabilityReports

        #if targetEnvironment(simulator)
        statusMessage = "Simulator nie obsługuje Apple Translation — użyj fizycznego iPhone (iOS 18+)."
        isRunning = false
        return
        #endif

        let installedPairs = availabilityReports.filter { $0.availability == .installed }
        guard !installedPairs.isEmpty else {
            statusMessage = "Brak zainstalowanych modeli — pobierz języki w Ustawienia → Aplikacje → Tłumacz. Rescue pozostaje na Supabase."
            isRunning = false
            return
        }

        statusMessage = "Tłumaczę próbki (\(installedPairs.count) par)…"
        for pair in installedPairs {
            await translateInstalledPair(pair)
        }

        translationConfig = nil
        translationWork = nil
        statusMessage = "Test zakończony. Wyniki powyżej — skopiuj do docs/APPLE_TRANSLATION_DEVICE_SPIKE_RESULTS.md."
        isRunning = false
    }

    private func translateInstalledPair(_ pair: AppleTranslationSpikePairReport) async {
        await withCheckedContinuation { continuation in
            pairTranslationContinuation = continuation
            translationGeneration += 1
            let generation = translationGeneration
            translationWork = SpikeTranslationWork(
                pairID: pair.id,
                source: Locale.Language(identifier: pair.sourceCode),
                target: Locale.Language(identifier: pair.targetCode),
                phrases: AppleTranslationSpikeCatalog.samplePhrases,
                generation: generation
            )
            translationConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: pair.sourceCode),
                target: Locale.Language(identifier: pair.targetCode)
            )
        }
    }

    private func performTranslationBatch(session: TranslationSession) async {
        guard let work = translationWork, work.generation == translationGeneration else {
            pairTranslationContinuation?.resume()
            pairTranslationContinuation = nil
            return
        }

        var phraseResults: [AppleTranslationSpikePhraseResult] = []
        for phrase in work.phrases {
            let started = Date()
            do {
                let response = try await session.translate(phrase)
                let latencyMs = Int(Date().timeIntervalSince(started) * 1000)
                phraseResults.append(
                    AppleTranslationSpikePhraseResult(
                        sourcePhrase: phrase,
                        translatedText: response.targetText,
                        latencyMs: latencyMs,
                        errorMessage: nil
                    )
                )
            } catch {
                phraseResults.append(
                    AppleTranslationSpikePhraseResult(
                        sourcePhrase: phrase,
                        translatedText: nil,
                        latencyMs: nil,
                        errorMessage: error.localizedDescription
                    )
                )
            }
        }

        if let index = reports.firstIndex(where: { $0.id == work.pairID }) {
            reports[index].phraseResults = phraseResults
        }

        pairTranslationContinuation?.resume()
        pairTranslationContinuation = nil
    }
}

@available(iOS 18, *)
private struct SpikeTranslationWork {
    let pairID: String
    let source: Locale.Language
    let target: Locale.Language
    let phrases: [String]
    let generation: Int
}

struct AppleTranslationSpikeUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Wymaga iOS 18",
            systemImage: "iphone.gen3",
            description: Text("Apple Translation spike działa na iOS 18+ na fizycznym urządzeniu (build Debug).")
        )
        .navigationTitle("Apple Translation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppleTranslationSpikeEntryView: View {
    var body: some View {
        if #available(iOS 18, *) {
            AppleTranslationSpikeView()
        } else {
            AppleTranslationSpikeUnavailableView()
        }
    }
}

#endif
