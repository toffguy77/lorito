import Testing
@testable import Domain

private func theme(_ id: String, _ level: CEFRLevel, order: Int) -> Theme {
    Theme(id: id, level: level, title: id, order: order)
}

private func card(_ id: String, _ level: CEFRLevel, theme: String, order: Int) -> Card {
    Card(id: id, level: level, themeID: theme, order: order, title: id, body: "")
}

/// A small catalog spanning A1, A2, B1 with one theme + one card each.
private let catalog = ContentCatalog(
    themes: [
        theme("a1-1", .a1, order: 1),
        theme("a2-1", .a2, order: 1),
        theme("b1-1", .b1, order: 1),
        theme("b2-1", .b2, order: 1),
    ],
    cards: [
        card("A1-01", .a1, theme: "a1-1", order: 1),
        card("A2-01", .a2, theme: "a2-1", order: 1),
        card("B1-01", .b1, theme: "b1-1", order: 1),
        card("B2-01", .b2, theme: "b2-1", order: 1),
    ]
)

@Suite("Selection scope helpers")
struct SelectionScopeTests {
    @Test("A1-only scope includes just A1")
    func a1Only() {
        #expect(SelectionScope.includedLevels(for: .a1) == [.a1])
    }

    @Test("B1 includes A1 through B1")
    func b1IncludesLower() {
        #expect(SelectionScope.includedLevels(for: .b1) == [.a1, .a2, .b1])
    }

    @Test("B2 includes A1 through B2")
    func b2IncludesLower() {
        #expect(SelectionScope.includedLevels(for: .b2) == [.a1, .a2, .b1, .b2])
    }

    @Test("In-scope themes cover only included levels, level-ordered")
    func inScopeThemes() {
        let themes = SelectionScope.inScopeThemes(for: [.a1, .a2], in: catalog)
        #expect(themes.map(\.id) == ["a1-1", "a2-1"])
    }

    @Test("In-scope cards filter by included level and selected theme")
    func inScopeCardsFilter() {
        let cards = SelectionScope.inScopeCards(
            targetLevel: .a2,
            selectedThemeIDs: ["a1-1", "a2-1"],
            in: catalog
        )
        #expect(cards.map(\.id) == ["A1-01", "A2-01"])  // B1/B2 excluded by level
    }

    @Test("Deselecting a theme drops its cards")
    func themeFilter() {
        let cards = SelectionScope.inScopeCards(
            targetLevel: .b1,
            selectedThemeIDs: ["a1-1"],  // only A1's theme selected
            in: catalog
        )
        #expect(cards.map(\.id) == ["A1-01"])
    }

    @Test("Empty selection is not studyable; non-empty is")
    func studyability() {
        #expect(!SelectionScope.isStudyable(targetLevel: .b1, selectedThemeIDs: [], in: catalog))
        #expect(!SelectionScope.isStudyable(targetLevel: nil, selectedThemeIDs: ["a1-1"], in: catalog))
        #expect(SelectionScope.isStudyable(targetLevel: .a1, selectedThemeIDs: ["a1-1"], in: catalog))
    }

    @Test("Helpers are deterministic for identical input")
    func determinism() {
        let a = SelectionScope.inScopeCards(targetLevel: .b1, selectedThemeIDs: ["a1-1", "a2-1", "b1-1"], in: catalog)
        let b = SelectionScope.inScopeCards(targetLevel: .b1, selectedThemeIDs: ["b1-1", "a1-1", "a2-1"], in: catalog)
        #expect(a == b)
    }
}
