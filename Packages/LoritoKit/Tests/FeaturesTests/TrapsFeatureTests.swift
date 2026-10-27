import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@Suite("Personal traps screens")
@MainActor
struct TrapsFeatureTests {
    func seeded() throws -> (SwiftDataUserDataStore, ContentCatalog) {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
        try store.saveSettings(UserSettings(targetLevel: .a1, didCompleteOnboarding: true))
        let yesterday = Calendar.learningDay.date(byAdding: .day, value: -1, to: Date())!
        try store.upsertReview(ReviewState(cardID: "A1-07", interval: 0, dueDate: Date(), status: .learning))
        try store.appendEvent(StudyEvent(cardID: "A1-07", date: yesterday, grade: "again"))
        return (store, try ContentLoader.loadCatalog())
    }

    @Test("Опять on a card with mistakes lists a trap; the session writes trap practice only")
    func session() throws {
        let (store, catalog) = try seeded()
        let model = TrapsModel(store: store, catalog: catalog)
        #expect(model.traps.map(\.cardID) == ["A1-07"])
        let before = try store.review(for: "A1-07")
        let s = try #require(model.makeSession())
        #expect(!s.mistakesSection.isEmpty && s.current?.firstMistake.isEmpty == false)
        s.answer(.clear)                        // ignored before reveal
        #expect(try store.allTrapPractice().isEmpty)
        s.reveal()
        s.answer(.clear)
        #expect(s.isComplete)
        #expect(try store.allTrapPractice().map(\.outcome) == [.clear])
        #expect(try store.review(for: "A1-07") == before)
        #expect(try store.allEvents().count == 1)
    }

    @Test("Count label plurals: 1 ловушка / 2 ловушки / 5 ловушек")
    func plurals() {
        #expect(TrapsModel.countLabel(1) == "1 ловушка")
        #expect(TrapsModel.countLabel(2) == "2 ловушки")
        #expect(TrapsModel.countLabel(5) == "5 ловушек")
    }
}
