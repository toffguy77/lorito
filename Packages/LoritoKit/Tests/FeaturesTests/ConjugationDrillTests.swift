import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@Suite("Conjugation drill")
@MainActor
struct ConjugationDrillTests {
    @Test("Check grades both persons, applies the worse grade via the scheduler and logs a study event")
    func drill() throws {
        let catalog = try #require(try ContentLoader.loadCatalog().conjugation)
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
        let model = ConjugationDrillModel(store: store, catalog: catalog, itemIDs: ["conj:hablar:preterito-indefinido"])
        #expect(model.persons.count == 2)
        model.answers = [model.expected(0), "xx"]
        model.check()
        #expect(model.results?.map(\.verdict) == [.correct, .wrong])
        let review = try #require(try store.review(for: "conj:hablar:preterito-indefinido"))
        #expect(review.lastGrade == Grade.again.rawValue)
        #expect(try store.allEvents().map(\.cardID) == ["conj:hablar:preterito-indefinido"])
        model.next()
        #expect(model.isComplete)
    }

    @Test("Accent row types into the focused field; missing accent is «почти»")
    func accents() throws {
        let catalog = try #require(try ContentLoader.loadCatalog().conjugation)
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
        let model = ConjugationDrillModel(store: store, catalog: catalog, itemIDs: ["conj:hablar:presente"])
        model.focusedField = 1
        model.insertAccent("ñ")
        #expect(model.answers[1] == "ñ")
        let plain = model.expected(0).folding(options: .diacriticInsensitive, locale: nil)
        model.answers = [plain, model.expected(1)]
        model.check()
        let first = try #require(model.results?.first)
        #expect(first.verdict == (plain == model.expected(0) ? .correct : .almost))
    }
}

@Suite("Conjugation settings and Today")
@MainActor
struct ConjugationSettingsTests {
    @Test("Off by default; enabling sets 3; quota clamps to 0–20; Today plans items once a tense is unlocked")
    func settingsAndToday() throws {
        let catalog = try ContentLoader.loadCatalog()
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
        try store.saveSettings(UserSettings(targetLevel: .a1, didCompleteOnboarding: true))
        let model = ConjugationSettingsModel(store: store)
        #expect(!model.isEnabled && model.quota == 0)
        let today = TodayModel(store: store, catalog: catalog, boosts: FirstSessionBoostStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        #expect(today.conjugationItems.isEmpty)
        model.isEnabled = true
        #expect(try store.loadSettings().dailyConjugationCount == 3)
        model.quota = 99
        #expect(model.quota == 20)
        model.quota = 3
        // Not unlocked yet: the presente card was never studied.
        today.refresh()
        #expect(today.conjugationItems.isEmpty)
        try store.upsertReview(ReviewState(cardID: "A1-19", interval: 3, repetitions: 1, dueDate: Date().addingTimeInterval(86_400 * 3), status: .review))
        today.refresh()
        #expect(today.conjugationItems.count == 3 && today.conjugationItems.allSatisfy { $0.hasSuffix(":presente") })
        #expect(today.conjugationItems.first == "conj:ser:presente" || today.conjugationItems.first?.hasPrefix("conj:") == true)
    }
}
