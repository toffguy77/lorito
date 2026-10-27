import Testing
@testable import Domain

@Suite("Related cards")
struct RelatedCardsTests {
    static func card(_ id: String, related: [String] = []) -> Card {
        Card(id: id, level: .a1, themeID: "a1-1", order: Int(id.suffix(2))!, title: "T\(id)", related: related, body: "")
    }

    @Test("Resolves related ids in order and skips unknown ones")
    func resolves() {
        let a = Self.card("A1-07", related: ["A1-11", "A1-99", "A1-08"])
        let catalog = ContentCatalog(themes: [], cards: [a, Self.card("A1-08"), Self.card("A1-11")])
        #expect(catalog.relatedCards(of: a).map(\.id) == ["A1-11", "A1-08"])
    }

    @Test("No related → empty; a card never lists itself")
    func emptyAndSelf() {
        let a = Self.card("A1-01", related: ["A1-01"])
        let catalog = ContentCatalog(themes: [], cards: [a])
        #expect(catalog.relatedCards(of: a).isEmpty)
        #expect(catalog.relatedCards(of: Self.card("A1-02")).isEmpty)
    }
}
