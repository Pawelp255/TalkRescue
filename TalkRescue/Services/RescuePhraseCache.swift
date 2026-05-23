import Foundation

/// Lightweight exact-match cache for common rescue phrases (Polish → English).
/// Keys are already normalized (lowercase, single spaces). Add entries to `lookup` only.
enum RescuePhraseCache {
    /// Normalized Polish → spoken English.
    private static let lookup: [String: String] = [
        "potrzebuję chwili": "I need a moment.",
        "nie rozumiem": "I don't understand.",
        "powtórz proszę": "Could you repeat that, please?",
        "zaraz wracam": "I'll be right back.",
        "muszę to sprawdzić": "I need to check that.",
        "jak to powiedzieć po angielsku": "How do you say that in English?",
        "moment proszę": "One moment, please.",
        "przepraszam": "Excuse me.",
        "nie mówię po angielsku": "I don't speak English.",
        "czy możesz mówić wolniej": "Could you speak more slowly?",
        "dziękuję": "Thank you.",
        "proszę bardzo": "You're welcome.",
        "czy możemy mówić wolniej": "Can we speak more slowly?",
        "nie wiem jak to powiedzieć": "I don't know how to say that.",
        "poczekaj chwilę": "Wait a moment.",
        "to zajmie chwilę": "This will take a moment.",
        "mogę to sprawdzić na telefonie": "I can check that on my phone.",
        "czy możesz to napisać": "Could you write that down?",
        "nie jestem pewien": "I'm not sure.",
        "rozumiem": "I understand.",
    ]

    static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Exact match on normalized Polish text.
    static func englishTranslation(for polishText: String) -> String? {
        let key = normalize(polishText)
        guard !key.isEmpty else { return nil }
        return lookup[key]
    }

    /// Call once at launch to verify cache wiring (debug builds only).
    static func validateLookup() {
        assert(englishTranslation(for: "nie rozumiem") == "I don't understand.")
    }
}
