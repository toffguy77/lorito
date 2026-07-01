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

    @Test("Pilot exercises load and resolve to same-level cards")
    func exercisesResolve() throws {
        let catalog = try ContentLoader.loadCatalog()
        #expect(!catalog.exercises.isEmpty)
        for ex in catalog.exercises {
            let card = catalog.card(id: ex.card)
            #expect(card != nil, "exercise \(ex.id) -> unresolved card \(ex.card)")
            #expect(card?.level == ex.level)
        }
        // The pilot drills the noun cards.
        #expect(!catalog.exercises(forCard: "A1-07").isEmpty)
        #expect(!catalog.exercises(forCard: "A1-08").isEmpty)
    }
}
