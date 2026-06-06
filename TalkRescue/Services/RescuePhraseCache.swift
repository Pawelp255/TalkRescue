import Foundation

/// Lightweight exact-match cache for common rescue phrases (Polish → target language).
/// Keys are normalized Polish text; lookups are namespaced per `LanguageProfile.cacheNamespace`.
enum RescuePhraseCache {
    private static let polishToEnglish: [String: String] = [
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

    private static let polishToSwedish: [String: String] = [
        "nie rozumiem": "Jag förstår inte.",
        "potrzebuję chwili": "Jag behöver en stund.",
        "powtórz proszę": "Kan du upprepa det?",
        "muszę to sprawdzić": "Låt mig kolla.",
        "dziękuję": "Tack.",
        "przepraszam": "Ursäkta.",
        "moment proszę": "Ett ögonblick, tack.",
    ]

    private static let polishToSpanish: [String: String] = [
        "nie rozumiem": "No entiendo.",
        "potrzebuję chwili": "Necesito un momento.",
        "powtórz proszę": "¿Puedes repetirlo?",
        "muszę to sprawdzić": "Déjame comprobarlo.",
        "dziękuję": "Gracias.",
        "przepraszam": "Perdón.",
        "moment proszę": "Un momento, por favor.",
    ]

    private static let polishToGerman: [String: String] = [
        "nie rozumiem": "Ich verstehe nicht.",
        "potrzebuję pomocy": "Ich brauche Hilfe.",
        "gdzie jest toaleta?": "Wo ist die Toilette?",
        "wezwij lekarza": "Rufen Sie einen Arzt.",
        "mówię tylko po polsku": "Ich spreche nur Polnisch.",
    ]

    private static let lookups: [String: [String: String]] = [
        LanguageProfile.polishToEnglish.cacheNamespace: polishToEnglish,
        LanguageProfile.polishToSwedish.cacheNamespace: polishToSwedish,
        LanguageProfile.polishToSpanish.cacheNamespace: polishToSpanish,
        LanguageProfile.polishToGerman.cacheNamespace: polishToGerman,
    ]

    static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Exact match on normalized Polish text for the given profile namespace.
    static func translation(for polishText: String, profile: LanguageProfile) -> String? {
        let key = normalize(polishText)
        guard !key.isEmpty else { return nil }
        return lookups[profile.cacheNamespace]?[key]
    }

    /// Backward-compatible PL→EN lookup.
    static func englishTranslation(for polishText: String) -> String? {
        translation(for: polishText, profile: .polishToEnglish)
    }

    /// Call once at launch to verify cache wiring (debug builds only).
    static func validateLookup() {
        assert(englishTranslation(for: "nie rozumiem") == "I don't understand.")
        assert(translation(for: "nie rozumiem", profile: .polishToSwedish) == "Jag förstår inte.")
        assert(translation(for: "nie rozumiem", profile: .polishToSpanish) == "No entiendo.")
        assert(translation(for: "nie rozumiem", profile: .polishToGerman) == "Ich verstehe nicht.")
        assert(translation(for: "gdzie jest toaleta?", profile: .polishToGerman) == "Wo ist die Toilette?")
    }
}
