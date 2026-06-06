import Foundation
import os

struct TranslationService {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Translation")

    private var endpoint: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TALKRESCUE_SUPABASE_URL") as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    private var apiKey: String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TALKRESCUE_API_KEY") as? String else {
            return ""
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        endpoint != nil && !apiKey.isEmpty
    }

    /// Establish TLS connection early to reduce first-request latency.
    static func warmConnection() async {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TALKRESCUE_SUPABASE_URL") as? String,
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        let started = Date()
        _ = try? await session.data(for: request)
        LaunchMetrics.log("Translation proxy connection warmup", since: started)
    }

    func translate(_ polishText: String, profile: LanguageProfile) async throws -> String {
        let trimmedText = polishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TranslationError.emptySpeech
        }

        guard let endpoint else {
            throw TranslationError.missingAPIKey
        }

        guard isConfigured else {
            throw TranslationError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = TranslateRequest(text: trimmedText, profileId: profile.id)
        request.httpBody = try JSONEncoder().encode(body)
        let started = Date()
        logger.info("Translation proxy request started.")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await Self.session.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            logger.error("Translation timed out.")
            throw TranslationError.timedOut
        } catch {
            logger.error("Translation network failure: \(error.localizedDescription, privacy: .public)")
            throw TranslationError.networkFailure
        }

        let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
        logger.info("Translation proxy response received durationMs=\(elapsedMs, privacy: .public)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkFailure
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(for: httpResponse.statusCode, data: data)
            logger.error("Translation API failure status=\(httpResponse.statusCode, privacy: .public) message=\(message, privacy: .public)")
            throw Self.translationError(for: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(TranslateResponse.self, from: data)
        let translation = Self.sanitizeOneLine(decoded.translation)

        guard !translation.isEmpty else {
            throw TranslationError.emptyResponse
        }

        logger.info("Translation succeeded durationMs=\(elapsedMs, privacy: .public) provider=\(decoded.provider ?? "unknown", privacy: .public)")
        return translation
    }

    /// Backward-compatible entry point for PL→EN callers.
    func translatePolishToEnglish(_ polishText: String) async throws -> String {
        try await translate(polishText, profile: .polishToEnglish)
    }

    private static func errorMessage(for statusCode: Int, data: Data) -> String {
        if let apiError = try? JSONDecoder().decode(TranslateErrorResponse.self, from: data),
           let message = apiError.message, !message.isEmpty {
            return message
        }
        return "\(L10n.Errors.translationFailed) (HTTP \(statusCode))."
    }

    private static func translationError(for statusCode: Int, message: String) -> TranslationError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 429:
            return .rateLimited
        case 504:
            return .timedOut
        case 502:
            return .networkFailure
        case 400:
            return .apiFailure(L10n.Errors.invalidTranslationRequest)
        default:
            return .apiFailure(message)
        }
    }

    private static func sanitizeOneLine(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("\""), text.hasSuffix("\""), text.count >= 2 {
            text = String(text.dropFirst().dropLast())
        }
        if let firstLine = text.split(whereSeparator: \.isNewline).first {
            text = String(firstLine)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TranslationError: LocalizedError {
    case missingAPIKey
    case unauthorized
    case rateLimited
    case emptySpeech
    case networkFailure
    case timedOut
    case apiFailure(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return L10n.Errors.translationNotConfigured
        case .unauthorized:
            return L10n.Errors.translationUnauthorized
        case .rateLimited:
            return L10n.Errors.translationRateLimited
        case .emptySpeech:
            return L10n.Main.noPolishCaught
        case .networkFailure:
            return L10n.Errors.networkFailed
        case .timedOut:
            return L10n.Errors.translationTimedOut
        case .apiFailure(let message):
            return message
        case .emptyResponse:
            return L10n.Errors.emptyTranslation
        }
    }
}

private struct TranslateRequest: Encodable {
    let text: String
    let profileId: String
}

private struct TranslateResponse: Decodable {
    let translation: String
    let provider: String?
}

private struct TranslateErrorResponse: Decodable {
    let error: String?
    let message: String?
    let retryAfter: Int?
}
