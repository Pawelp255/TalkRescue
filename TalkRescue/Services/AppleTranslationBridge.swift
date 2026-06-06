import Foundation
import SwiftUI

enum AppleTranslationError: LocalizedError {
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Apple translation returned an empty response."
        }
    }
}

struct AppleTranslationHostContainer: View {
    var body: some View {
        if #available(iOS 18, *) {
            AppleTranslationHostViewRepresentable()
        }
    }
}

@available(iOS 18, *)
private struct AppleTranslationHostViewRepresentable: View {
    var body: some View {
        #if canImport(Translation)
        AppleTranslationHostBody()
        #else
        EmptyView()
        #endif
    }
}

#if canImport(Translation)
import Translation

@available(iOS 18, *)
@MainActor
final class AppleTranslationBridge: ObservableObject {
    static let shared = AppleTranslationBridge()

    private(set) var configuration: TranslationSession.Configuration?
    private var pendingRequest: PendingRequest?
    private var requestGeneration: UInt = 0

    private struct PendingRequest {
        let text: String
        let continuation: CheckedContinuation<String, Error>
        let generation: UInt
    }

    private init() {}

    func translate(
        text: String,
        source: Locale.Language,
        target: Locale.Language
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            requestGeneration += 1
            pendingRequest = PendingRequest(
                text: text,
                continuation: continuation,
                generation: requestGeneration
            )
            triggerConfiguration(source: source, target: target)
        }
    }

    func handleSession(_ session: TranslationSession) async {
        guard let request = pendingRequest else { return }
        defer { pendingRequest = nil }

        do {
            let response = try await session.translate(request.text)
            let translation = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translation.isEmpty else {
                request.continuation.resume(throwing: AppleTranslationError.emptyResponse)
                return
            }
            request.continuation.resume(returning: translation)
        } catch {
            request.continuation.resume(throwing: error)
        }
    }

    private func triggerConfiguration(source: Locale.Language, target: Locale.Language) {
        let newConfiguration = TranslationSession.Configuration(source: source, target: target)
        if var current = configuration {
            current.invalidate()
            configuration = current
        }
        configuration = newConfiguration
    }
}

@available(iOS 18, *)
private struct AppleTranslationHostBody: View {
    @ObservedObject private var bridge = AppleTranslationBridge.shared

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .translationTask(bridge.configuration) { session in
                await bridge.handleSession(session)
            }
    }
}

#endif
