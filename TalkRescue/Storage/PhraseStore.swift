import Foundation

@MainActor
final class PhraseStore: ObservableObject {
    @Published private(set) var history: [Phrase] = []
    @Published private(set) var favorites: [Phrase] = []

    private let historyKey = "talkRescue.history"
    private let favoritesKey = "talkRescue.favorites"
    private let maxHistoryCount = 10

    init() {
        history = load(forKey: historyKey)
        favorites = load(forKey: favoritesKey)
    }

    func addToHistory(polishText: String, englishText: String) {
        let phrase = Phrase(polishText: polishText, englishText: englishText)
        history.removeAll { $0.polishText == polishText && $0.englishText == englishText }
        history.insert(phrase, at: 0)
        history = Array(history.prefix(maxHistoryCount))
        save(history, forKey: historyKey)
    }

    func saveFavorite(polishText: String, englishText: String) {
        let phrase = Phrase(polishText: polishText, englishText: englishText)
        guard !favorites.contains(where: { $0.englishText == englishText }) else { return }
        favorites.insert(phrase, at: 0)
        save(favorites, forKey: favoritesKey)
    }

    func removeFavorite(_ phrase: Phrase) {
        favorites.removeAll { $0.id == phrase.id }
        save(favorites, forKey: favoritesKey)
    }

    private func load(forKey key: String) -> [Phrase] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }

        do {
            return try JSONDecoder().decode([Phrase].self, from: data)
        } catch {
            return []
        }
    }

    private func save(_ phrases: [Phrase], forKey key: String) {
        do {
            let data = try JSONEncoder().encode(phrases)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to save phrases: \(error.localizedDescription)")
        }
    }
}
