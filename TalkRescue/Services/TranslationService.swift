import Foundation
import os

struct TranslationService {
    private static let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private let model = "gpt-4o-mini"
    private let logger = Logger(subsystem: "com.pawelp.talkrescue", category: "Translation")

    private var apiKey: String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String else {
            return ""
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    /// Establish TLS connection early to reduce first-request latency.
    static func warmConnection() async {
        guard let url = URL(string: "https://api.openai.com") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        let started = Date()
        _ = try? await session.data(for: request)
        LaunchMetrics.log("OpenAI connection warmup", since: started)
    }

    func translatePolishToEnglish(_ polishText: String) async throws -> String {
        let trimmedText = polishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TranslationError.emptySpeech
        }

        guard isConfigured else {
            throw TranslationError.missingAPIKey
        }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                Message(role: "system", content: "PL→EN. One spoken English line only. No quotes."),
                Message(role: "user", content: trimmedText)
            ],
            temperature: 0,
            maxTokens: 64
        )

        request.httpBody = try JSONEncoder().encode(body)
        let started = Date()
        logger.info("OpenAI request started.")

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
        logger.info("OpenAI response received durationMs=\(elapsedMs, privacy: .public)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkFailure
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
            let message = apiError?.error.message ?? "\(L10n.Errors.translationFailed) (HTTP \(httpResponse.statusCode))."
            logger.error("Translation API failure: \(message, privacy: .public)")
            throw TranslationError.apiFailure(message)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let raw = decoded.choices.first?.message.content ?? ""
        let translation = Self.sanitizeOneLine(raw)

        guard !translation.isEmpty else {
            throw TranslationError.emptyResponse
        }

        logger.info("Translation succeeded durationMs=\(elapsedMs, privacy: .public)")
        return translation
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
    case emptySpeech
    case networkFailure
    case timedOut
    case apiFailure(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return L10n.Errors.translationNotConfigured
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

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct Message: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }
}

private struct OpenAIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
