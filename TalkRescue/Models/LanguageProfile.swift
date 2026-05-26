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
        ttsVoiceLanguage: "en-US",
        openAISystemPrompt: "PL→EN. One spoken English line only. No quotes.",
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
        ttsVoiceLanguage: "sv-SE",
        openAISystemPrompt: "PL→SV. One spoken Swedish line only. No quotes.",
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

    static let all: [LanguageProfile] = [.polishToEnglish, .polishToSwedish]
    static let `default` = polishToEnglish

    static func profile(id: String) -> LanguageProfile? {
        all.first { $0.id == id }
    }
}
