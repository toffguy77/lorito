import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@Suite("Words")
@MainActor
struct VocabularyFeatureTests {
    func make() throws -> (VocabularyModel, SwiftDataUserDataStore) {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
        try store.saveSettings(UserSettings(targetLevel: .a1, didCompleteOnboarding: true))
        return (VocabularyModel(store: store, catalog: try ContentLoader.loadCatalog()), store)
    }

    @Test("«В мои слова»: a bundled word (any form) joins the personal deck once; unknown needs a translation")
    func save() throws {
        let (m, store) = try make()
        #expect(m.save("casas") == .added("la casa"))
        #expect(m.save("Casa") == .alreadySaved("la casa"))
        #expect(m.save("madrugar") == .unknown("madrugar"))
        m.saveUnknown("madrugar", ru: "рано вставать")
        #expect(m.personalEntries.map(\.es) == ["la casa", "madrugar"])
        #expect(try store.allPersonalWords().count == 1)
    }

    @Test("Deleting a personal word removes it and its review state; study events stay")
    func delete() throws {
        let (m, store) = try make()
        m.saveUnknown("madrugar", ru: "рано вставать")
        let pid = try #require(m.personalEntries.first?.id)
        try store.upsertReview(ReviewState(cardID: Word.itemID(pid), interval: 1, status: .learning))
        try store.appendEvent(StudyEvent(cardID: Word.itemID(pid), date: Date(), grade: "good"))
        m.deletePersonal(pid)
        #expect(try m.personalEntries.isEmpty && store.allPersonalWords().isEmpty)
        #expect(try store.review(for: Word.itemID(pid)) == nil && store.allEvents().count == 1)
    }

    @Test("Off by default; enabling sets 5; today's words personal first; a session grades through the SRS")
    func plan() throws {
        let (m, store) = try make()
        #expect(m.todayItems().isEmpty)
        m.setEnabled(true)
        #expect(m.quota == 5)
        _ = m.save("viaje")
        let items = m.todayItems()
        #expect(items.count == 5 && items.first == "word:viaje")
        let s = try #require(WordSessionModel.make(m, items: items))
        #expect(s.mode == .recognition)
        s.reveal()
        s.selfGrade(.good)
        #expect(try store.review(for: "word:viaje")?.lastGrade == "good")
    }

    @Test("Production after two passing days; wrong article reported as a gender mistake")
    func production() throws {
        let (m, store) = try make()
        let cal = Calendar.learningDay
        for d in [-3, -1] {
            try store.appendEvent(StudyEvent(cardID: "word:casa", date: cal.date(byAdding: .day, value: d, to: Date())!, grade: "good"))
        }
        let s = try #require(WordSessionModel.make(m, items: ["word:casa"]))
        #expect(s.mode == .production)
        s.typed = "el casa"
        s.submit()
        #expect(s.check?.note == .genderMistake && s.check?.grade == .again)
    }
}
