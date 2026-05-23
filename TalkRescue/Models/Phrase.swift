import Foundation

struct Phrase: Identifiable, Codable, Equatable {
    let id: UUID
    let polishText: String
    let englishText: String
    let createdAt: Date

    init(id: UUID = UUID(), polishText: String, englishText: String, createdAt: Date = Date()) {
        self.id = id
        self.polishText = polishText
        self.englishText = englishText
        self.createdAt = createdAt
    }
}
