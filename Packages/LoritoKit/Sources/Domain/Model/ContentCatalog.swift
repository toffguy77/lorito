// The full in-memory content set, decoded from the compiled bundle.

public struct ContentCatalog: Codable, Sendable {
    public let themes: [Theme]
    public let cards: [Card]
    public let exercises: [Exercise]

    public init(themes: [Theme], cards: [Card], exercises: [Exercise] = []) {
        self.themes = themes
        self.cards = cards
        self.exercises = exercises
    }

    private enum CodingKeys: String, CodingKey {
        case themes, cards, exercises
    }

    // Custom init so a bundle without an `exercises` key still decodes.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        themes = try c.decode([Theme].self, forKey: .themes)
        cards = try c.decode([Card].self, forKey: .cards)
        exercises = try c.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
    }

    /// Levels that actually have content, in CEFR order.
    public var levels: [CEFRLevel] {
        let present = Set(cards.map(\.level))
        return CEFRLevel.allCases.filter { present.contains($0) }
    }

    public func card(id: String) -> Card? {
        cards.first { $0.id == id }
    }

    public func theme(id: String) -> Theme? {
        themes.first { $0.id == id }
    }

    public func themes(in level: CEFRLevel) -> [Theme] {
        themes.filter { $0.level == level }.sorted { $0.order < $1.order }
    }

    public func cards(in level: CEFRLevel) -> [Card] {
        cards.filter { $0.level == level }.sorted { $0.order < $1.order }
    }

    public func cards(themeID: String) -> [Card] {
        cards.filter { $0.themeID == themeID }.sorted { $0.order < $1.order }
    }

    public func exercise(id: String) -> Exercise? {
        exercises.first { $0.id == id }
    }

    /// Exercises drilling a given card.
    public func exercises(forCard cardID: String) -> [Exercise] {
        exercises.filter { $0.card == cardID }
    }

    public func exercises(themeID: String) -> [Exercise] {
        exercises.filter { $0.themeID == themeID }
    }

    public func exercises(in level: CEFRLevel) -> [Exercise] {
        exercises.filter { $0.level == level }
    }
}
