import Testing
import Foundation
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

    @Test("Picture-matching image assets are bundled and resolve via Bundle.module")
    func pictureAssetsResolve() throws {
        let catalog = try ContentLoader.loadCatalog()
        // Every image referenced by a picture-matching exercise must resolve to a bundled file.
        for ex in catalog.exercises {
            guard case let .pictureMatching(options) = ex.kind else { continue }
            for opt in options {
                let url = ContentLoader.exerciseAssetURL(opt.image)
                #expect(url != nil, "asset \(opt.image) (exercise \(ex.id)) did not resolve in the bundle")
                if let url { #expect((try? Data(contentsOf: url))?.isEmpty == false) }
            }
        }
    }
}
