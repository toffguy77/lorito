// The full in-memory content set, decoded from the compiled bundle.

public struct ContentCatalog: Codable, Sendable {
    public let themes: [Theme]
    public let cards: [Card]

    public init(themes: [Theme], cards: [Card]) {
        self.themes = themes
        self.cards = cards
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
}
