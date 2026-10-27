import Testing
import Foundation
import Domain
@testable import Features

private final class MemoryStore: UserDataStore {
    var settings = UserSettings.default
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []

    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ review: ReviewState) throws { reviews[review.cardID] = review }
    func appendEvent(_ event: StudyEvent) throws { events.append(event) }
    func allEvents() throws -> [StudyEvent] { events }
}

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "T", order: 1), Theme(id: "a2-1", level: .a2, title: "T2", order: 1)],
    cards: [
        Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A", body: ""),
        Card(id: "A1-02", level: .a1, themeID: "a1-1", order: 2, title: "B", body: ""),
        Card(id: "A2-01", level: .a2, themeID: "a2-1", order: 1, title: "C", body: ""),
    ]
)

private let today = Calendar.learningDay(in: TimeZone(identifier: "UTC")!).date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 12))!

@Suite("Progress insights models")
@MainActor
struct ProgressInsightsModelTests {
    @Test("StatsModel exposes the 84-day series, buckets, window total and memory rows")
    func statsModel() {
        let store = MemoryStore()
        store.settings = UserSettings(targetLevel: .a2, selectedThemeIDs: ["a1-1", "a2-1"], dailyNewCardCount: 5)
        store.events = [StudyEvent(cardID: "A1-01", date: today, grade: "good"),
                        StudyEvent(cardID: "A1-02", date: today, grade: "good")]
        store.reviews["A1-01"] = ReviewState(cardID: "A1-01", interval: 25, repetitions: 4, status: .review)
        let model = StatsModel(store: store, catalog: catalog, today: today)
        #expect(model.activity.count == 84)
        #expect(model.activity.last?.count == 2)
        #expect(model.buckets.last == 3)
        #expect(model.windowTotal == 2)
        #expect(model.memory.map(\.level) == [.a1, .a2])
        #expect(model.memory.first?.longTerm == 1)
        #expect(model.memory.first?.total == 2)
    }

    @Test("Week strip: seven days ending today, studied flags, Russian weekday labels")
    func weekStrip() {
        let store = MemoryStore()
        store.settings = UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1"], dailyNewCardCount: 1)
        let yesterday = Calendar.learningDay(in: TimeZone(identifier: "UTC")!).date(byAdding: .day, value: -1, to: today)!
        store.events = [StudyEvent(cardID: "A1-01", date: yesterday, grade: "good")]
        let model = TodayModel(store: store, catalog: catalog, today: { today })
        #expect(model.week.count == 7)
        #expect(model.week.last?.isToday == true)
        #expect(model.week.last?.studied == false)
        #expect(model.week[5].studied)
        #expect(model.week.last?.label == "Вт")   // 2026-10-27 is a Tuesday
        #expect(model.week.map(\.label) == ["Ср", "Чт", "Пт", "Сб", "Вс", "Пн", "Вт"])

        store.events.append(StudyEvent(cardID: "A1-02", date: today, grade: "good"))
        model.refresh()
        #expect(model.week.last?.studied == true)
    }
}
