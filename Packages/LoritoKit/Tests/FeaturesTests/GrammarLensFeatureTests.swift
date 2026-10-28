import Foundation
import Testing
import Domain
import Content
import Persistence
import WidgetSupport
@testable import Features

@MainActor
private func freshStore() throws -> SwiftDataUserDataStore {
    SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
}
final class LensRecorder: AnalyticsRecording {
    var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) { events.append(event) }
}

@Suite("Grammar Lens model")
@MainActor
struct GrammarLensFeatureTests {
    let now = Date()

    func model(_ store: UserDataStore, _ recorder: LensRecorder = LensRecorder(), source: LensSource = .paste) throws -> LensModel {
        LensModel(store: store, catalog: try ContentLoader.loadCatalog(), lens: try ContentLoader.loadLens(),
                  source: source, analytics: recorder, now: { now })
    }

    @Test("Analysing highlights the span with the rule's Russian name and its cards; analytics carry no text")
    func analyze() throws {
        let recorder = LensRecorder()
        let m = try model(try freshStore(), recorder)
        #expect(recorder.events == [.lensOpened(source: .paste)])
        m.text = "Espero que vengas mañana. Tengo un problema."
        m.analyze()
        #expect(m.highlights.map(\.text) == ["Espero que vengas", "un problema"])
        #expect(m.highlights[0].title == "Subjuntivo после желания (quiero que…)")
        #expect(m.highlights[0].cards.map(\.id) == ["B1-02"])
        #expect(m.highlights[1].cards.map(\.id) == ["A1-07"])
        #expect(recorder.events.last == .lensAnalyzed(source: .paste, matches: .few))
    }

    @Test("No construction: no highlights, the empty state lists covered topics")
    func empty() throws {
        let m = try model(try freshStore())
        m.text = "Hola."
        m.analyze()
        #expect(m.highlights.isEmpty && m.didAnalyze)
        #expect(m.coveredTopics.count >= 20)
    }

    @Test("«Добавить в повторение» requests a new card; it then comes first among today's new items")
    func request() throws {
        let store = try freshStore()
        try store.saveSettings(UserSettings(targetLevel: .a1, dailyNewCardCount: 3, didCompleteOnboarding: true))
        let recorder = LensRecorder()
        let m = try model(store, recorder)
        #expect(m.status(for: "B1-02") == .new)
        m.request("B1-02")
        #expect(try store.allRequestedItems().map(\.itemID) == ["B1-02"])
        #expect(m.status(for: "B1-02") == .requested)
        #expect(recorder.events.last == .lensCardRequested(card: CatalogCardID("B1-02")!))
        let today = TodayModel(store: store, catalog: try ContentLoader.loadCatalog(),
                               boosts: FirstSessionBoostStore(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        #expect(today.sessionQueue().first == "B1-02")
    }

    @Test("A scheduled card isn't moved: «Уже в повторении — через 9 дней»")
    func scheduled() throws {
        let store = try freshStore()
        let due = Calendar.learningDay.date(byAdding: .day, value: 9, to: now)!
        let state = ReviewState(cardID: "A1-07", interval: 9, repetitions: 3, dueDate: due, status: .review)
        try store.upsertReview(state)
        let m = try model(store)
        #expect(m.status(for: "A1-07") == .scheduled(days: 9))
        #expect(LensModel.statusText(.scheduled(days: 9)) == "Уже в повторении — через 9 дней")
        #expect(LensModel.statusText(.scheduled(days: 0)) == "Уже в повторении — сегодня")
        m.request("A1-07")
        #expect(try store.allRequestedItems().isEmpty)
        #expect(try store.review(for: "A1-07") == state)
    }
}

@Suite("Grammar Lens deep link")
struct LensDeepLinkTests {
    @Test("lorito://lens carries the text in the URL; other links aren't lens links")
    func roundTrip() {
        let text = "Espero que vengas & ¿qué tal?"
        #expect(LoritoDeepLink.lensText(LoritoDeepLink.lens(text: text)) == text)
        #expect(LoritoDeepLink.lensText(LoritoDeepLink.today) == nil)
        #expect(!LoritoDeepLink.isToday(LoritoDeepLink.lens(text: "x")))
    }
}
