import Testing
import Domain
@testable import Content

@Suite("Content bundle")
struct ContentTests {
    @Test("Catalog loads with cards and themes")
    func catalogLoads() throws {
        let catalog = try ContentLoader.loadCatalog()
        #expect(!catalog.cards.isEmpty)
        #expect(!catalog.themes.isEmpty)
    }

    @Test("All related and theme references resolve")
    func referencesResolve() throws {
        let catalog = try ContentLoader.loadCatalog()
        let ids = Set(catalog.cards.map(\.id))
        let themeIDs = Set(catalog.themes.map(\.id))
        for card in catalog.cards {
            #expect(themeIDs.contains(card.themeID), "card \(card.id) -> unknown theme \(card.themeID)")
            for r in card.related {
                #expect(ids.contains(r), "card \(card.id) -> unresolved related \(r)")
            }
        }
    }

    @Test("Levels present in CEFR order")
    func levelsOrdered() throws {
        let catalog = try ContentLoader.loadCatalog()
        #expect(catalog.levels == catalog.levels.sorted())
        #expect(catalog.levels.first == .a1)
    }
}
