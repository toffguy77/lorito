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

@Suite("Bundled exam content")
struct BundledExamContentTests {
    @Test("DELE A2 definition and three mock forms decode; form 1 reading is the preview")
    func exams() throws {
        let exams = try #require(try ContentLoader.loadCatalog().exams)
        #expect(exams.definition("dele-a2")?.groups.count == 2 && exams.definition("ccse") != nil)
        #expect(exams.forms(exam: "dele-a2") == [1, 2, 3])
        #expect(exams.isPreview(exam: "dele-a2", form: 1) && !exams.isPreview(exam: "dele-a2", form: 2))
        #expect(exams.items(exam: "dele-a2", form: 1).filter { $0.preview }.allSatisfy { $0.section == "reading" })
    }

    @Test("CCSE: 12 mock forms of 25 attributed questions; form 1 is the preview")
    func ccse() throws {
        let exams = try #require(try ContentLoader.loadCatalog().exams)
        #expect(exams.forms(exam: "ccse") == Array(1...12))
        for form in 1...12 {
            let items = exams.items(exam: "ccse", form: form)
            #expect(items.count == 25)
            #expect(items.allSatisfy { $0.source == "cervantes-ccse" && $0.edition == "2026" })
            #expect(items.allSatisfy { $0.preview == (form == 1) })
        }
    }
}

@Suite("Bundled vocabulary coverage")
struct VocabularyCoverageTests {
    @Test("A1–B2 carry at least 450 words each, C1–C2 at least 350; every deck at least 20; ids unique")
    func coverage() throws {
        let decks = try #require(try ContentLoader.loadCatalog().vocabulary).decks
        let minimum: [CEFRLevel: Int] = [.a1: 450, .a2: 450, .b1: 450, .b2: 450, .c1: 350, .c2: 350]
        for (level, min) in minimum {
            let count = decks.filter { $0.level == level }.reduce(0) { $0 + $1.words.count }
            #expect(count >= min, "\(level): \(count)")
        }
        for deck in decks { #expect(deck.words.count >= 20, "\(deck.id): \(deck.words.count)") }
        let ids = decks.flatMap { $0.words.map(\.id) }
        #expect(Set(ids).count == ids.count)
    }
}
