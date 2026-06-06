import Foundation

/// Describes a Polish-source rescue translation pair (speech locale + target language).
struct LanguageProfile: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let sourceLanguageName: String
    let targetLanguageName: String
    let sourceLocaleIdentifier: String
    let targetLocaleIdentifier: String
    let displayTitle: String
    let shortLabel: String
    /// Single-line chip label for narrow screens (e.g. iPhone SE).
    let chipCompactLabel: String
    let ttsVoiceLanguage: String
    let openAISystemPrompt: String
    let cacheNamespace: String
    let quickPhrases: [String]
    let autoSpeakToggleLabel: String
    let processingStatusLabel: String

    static let polishToEnglish = LanguageProfile(
        id: "pl-en",
        sourceLanguageName: "Polish",
        targetLanguageName: "English",
        sourceLocaleIdentifier: "pl-PL",
        targetLocaleIdentifier: "en-US",
        displayTitle: "Polski → Angielski",
        shortLabel: "Angielski",
        chipCompactLabel: "Ang.",
        ttsVoiceLanguage: "en-US",
        openAISystemPrompt:
            "Translate Polish to natural spoken English. Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal or literary. Preserve meaning. No quotes or labels.",
        cacheNamespace: "pl-en",
        quickPhrases: [
            "Can you repeat that?",
            "I need a moment.",
            "I don't understand.",
            "Let me check.",
            "I will call you back later."
        ],
        autoSpeakToggleLabel: "Czytaj po angielsku",
        processingStatusLabel: "Pobieram angielski…"
    )

    static let polishToSwedish = LanguageProfile(
        id: "pl-sv",
        sourceLanguageName: "Polish",
        targetLanguageName: "Swedish",
        sourceLocaleIdentifier: "pl-PL",
        targetLocaleIdentifier: "sv-SE",
        displayTitle: "Polski → Szwedzki",
        shortLabel: "Szwedzki",
        chipCompactLabel: "Szw.",
        ttsVoiceLanguage: "sv-SE",
        openAISystemPrompt:
            "Translate Polish to natural spoken Swedish (Sweden). Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal. Preserve meaning. No quotes or labels.",
        cacheNamespace: "pl-sv",
        quickPhrases: [
            "Kan du upprepa det?",
            "Jag behöver en stund.",
            "Jag förstår inte.",
            "Låt mig kolla.",
            "Jag ringer tillbaka senare."
        ],
        autoSpeakToggleLabel: "Czytaj po szwedzku",
        processingStatusLabel: "Pobieram szwedzki…"
    )

    static let polishToSpanish = LanguageProfile(
        id: "pl-es",
        sourceLanguageName: "Polish",
        targetLanguageName: "Spanish",
        sourceLocaleIdentifier: "pl-PL",
        targetLocaleIdentifier: "es-ES",
        displayTitle: "Polski → Hiszpański",
        shortLabel: "Hiszpański",
        chipCompactLabel: "His.",
        ttsVoiceLanguage: "es-ES",
        openAISystemPrompt:
            "Translate Polish to natural spoken Spanish (Spain). Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal. Preserve meaning. No quotes or labels.",
        cacheNamespace: "pl-es",
        quickPhrases: [
            "¿Puedes repetirlo?",
            "Necesito un momento.",
            "No entiendo.",
            "Déjame comprobarlo.",
            "Te llamo más tarde."
        ],
        autoSpeakToggleLabel: "Czytaj po hiszpańsku",
        processingStatusLabel: "Pobieram hiszpański…"
    )

    static let polishToGerman = LanguageProfile(
        id: "pl-de",
        sourceLanguageName: "Polish",
        targetLanguageName: "German",
        sourceLocaleIdentifier: "pl-PL",
        targetLocaleIdentifier: "de-DE",
        displayTitle: "Polski → Niemiecki",
        shortLabel: "Niemiecki",
        chipCompactLabel: "Niem.",
        ttsVoiceLanguage: "de-DE",
        openAISystemPrompt:
            "Translate Polish to natural spoken German (Germany). Output exactly one short sentence someone would say aloud in conversation. Friendly and clear, not formal. Preserve meaning. No quotes or labels.",
        cacheNamespace: "pl-de",
        quickPhrases: [
            "Können Sie das wiederholen?",
            "Ich brauche einen Moment.",
            "Ich verstehe nicht.",
            "Lassen Sie mich nachsehen.",
            "Ich rufe später zurück."
        ],
        autoSpeakToggleLabel: "Czytaj po niemiecku",
        processingStatusLabel: "Pobieram niemiecki…"
    )

    static let all: [LanguageProfile] = [
        .polishToEnglish, .polishToSwedish, .polishToSpanish, .polishToGerman,
    ]
    static let `default` = polishToEnglish

    static func profile(id: String) -> LanguageProfile? {
        all.first { $0.id == id }
    }
}
