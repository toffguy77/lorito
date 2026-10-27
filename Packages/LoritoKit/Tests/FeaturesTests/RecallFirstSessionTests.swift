import Testing
import Foundation
import Domain
import DesignSystem
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

private let mistakesBody = """
> **Суть**
> Два рода.

## ⚠️ Частые ошибки
- **Род по переводу**: *el problema*.
- Второй пункт.
"""

private let catalog = ContentCatalog(
    themes: [
        Theme(id: "a1-1", level: .a1, title: "Орфография", order: 1),
        Theme(id: "a1-2", level: .a1, title: "Существительное", order: 2),
    ],
    cards: [
        Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "Алфавит", body: "> **Суть**\n> Буквы.",
             recall: "**Сколько букв?** *abecedario*"),
        Card(id: "A1-02", level: .a1, themeID: "a1-2", order: 2, title: "Род", related: ["A1-03", "A1-77", "A1-01"], body: mistakesBody),
        Card(id: "A1-03", level: .a1, themeID: "a1-2", order: 3, title: "Артикли", aliases: ["El artículo"], body: mistakesBody),
    ]
)

@Suite("Recall-first study session")
@MainActor
struct RecallFirstSessionTests {
    @Test("Card opens unrevealed; grading is impossible before reveal")
    func gradeNeedsReveal() {
        let store = MemoryStore()
        let session = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01", "A1-02"])
        #expect(!session.isRevealed)
        session.grade(.good)
        #expect(session.currentCard?.id == "A1-01")
        #expect(store.events.isEmpty)
        #expect(store.reviews.isEmpty)
    }

    @Test("Reveal, grade, and the next card starts unrevealed")
    func revealResetsOnAdvance() {
        let session = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ["A1-01", "A1-02"])
        session.reveal()
        #expect(session.isRevealed)
        session.grade(.good)
        #expect(session.currentCard?.id == "A1-02")
        #expect(!session.isRevealed)
    }

    @Test("Recall prompt: card field, or a fallback that includes the title")
    func recallPrompt() {
        let session = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ["A1-01", "A1-03"])
        #expect(session.recallPrompt == "**Сколько букв?** *abecedario*")
        session.reveal(); session.grade(.good)
        #expect(session.recallPrompt.contains("Артикли"))
        #expect(session.recallHint == "El artículo")
    }

    @Test("Captions match the Domain preview for the card's stored state")
    func captionsMatchDomain() {
        let store = MemoryStore()
        let state = ReviewState(cardID: "A1-01", interval: 3, repetitions: 2, dueDate: Date(), status: .review)
        store.reviews["A1-01"] = state
        let session = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01"])
        let expected = IntervalPreview.captions(for: state, today: session.today)
        for grade in Grade.allCases {
            #expect(session.captions[grade.studyGrade] == expected[grade])
        }
        #expect(session.captions[.again] == "сегодня")
    }

    @Test("Preview does not change state")
    func previewIsReadOnly() {
        let store = MemoryStore()
        let session = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01"])
        session.reveal()
        _ = session.captions
        #expect(store.reviews.isEmpty && store.events.isEmpty)
    }

    @Test("Summary at completion reflects the session")
    func summary() {
        let session = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ["A1-01", "A1-02", "A1-03"])
        #expect(session.summary == nil)
        // A1-02 graded Опять returns once at the end; its second grade only logs.
        for grade: StudyGrade in [.good, .again, .hard, .good] { session.reveal(); session.grade(grade) }
        let summary = session.summary
        #expect(summary?.studied == 3)
        #expect(summary?.firstTryPercent == 33)
        #expect(summary?.currentStreak == 1)
        #expect(session.revisitThemeTitles == ["Существительное"])
    }
}

@Suite("Related cards in the session")
@MainActor
struct SessionRelatedCardsTests {
    @Test("Related cards appear only after reveal, resolved in order, unknown skipped")
    func related() {
        let session = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ["A1-02"])
        #expect(session.visibleRelatedCards.isEmpty)        // front side
        session.reveal()
        #expect(session.visibleRelatedCards.map(\.id) == ["A1-03", "A1-01"])
    }
}

@Suite("Trap of the day")
@MainActor
struct TrapOfTheDayTests {
    @Test("Today exposes a trap from an in-scope card with a mistakes section")
    func trap() {
        let store = MemoryStore()
        store.settings = UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1", "a1-2"], dailyNewCardCount: 3)
        let model = TodayModel(store: store, catalog: catalog)
        let trap = model.trap
        #expect(["A1-02", "A1-03"].contains(trap?.cardID ?? ""))
        #expect(trap?.text == "**Род по переводу**: *el problema*.")
        #expect(TodayModel(store: store, catalog: catalog).trap == trap)  // same day, same trap
    }

    @Test("No trap when no in-scope card has mistakes")
    func noTrap() {
        let store = MemoryStore()
        store.settings = UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1"], dailyNewCardCount: 3)
        #expect(TodayModel(store: store, catalog: catalog).trap == nil)
    }
}

@Suite("In-session relearn")
@MainActor
struct InSessionRelearnTests {
    private func gradeCurrent(_ s: StudySessionModel, _ g: StudyGrade) { s.reveal(); s.grade(g) }

    @Test("A card graded Опять returns once after the last card, on its front side")
    func returnsAtTheEnd() {
        let store = MemoryStore()
        let s = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01", "A1-02", "A1-03"])
        gradeCurrent(s, .again)                          // A1-01 → re-queued
        #expect(s.totalCount == 4)
        gradeCurrent(s, .good)                           // A1-02
        gradeCurrent(s, .good)                           // A1-03
        #expect(s.currentCard?.id == "A1-01")
        #expect(!s.isRevealed)
        #expect(!s.isComplete)
    }

    @Test("Only once: Опять on the re-shown card ends the session; review state unchanged")
    func onlyOnce() {
        let store = MemoryStore()
        let s = StudySessionModel(store: store, catalog: catalog, queue: ["A1-01"])
        gradeCurrent(s, .again)
        let stateAfterFirst = store.reviews["A1-01"]
        #expect(s.currentCard?.id == "A1-01")
        gradeCurrent(s, .again)
        #expect(s.isComplete)
        #expect(store.reviews["A1-01"] == stateAfterFirst)
        #expect(store.events.filter { $0.cardID == "A1-01" }.count == 2)
    }

    @Test("Progress counts the re-shown card as an extra step (5/13 → 6/14)")
    func progress() {
        let ids = (1...3).map { String(format: "A1-%02d", $0) }
        let s = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ids)
        #expect(s.positionText == "1 / 3")
        gradeCurrent(s, .again)
        #expect(s.positionText == "2 / 4")
        #expect(s.segments.count == 4)
        #expect(s.segments.first == .missed)
    }

    @Test("Captions on the re-shown card show the unchanged due date for every grade")
    func relearnCaptions() {
        let s = StudySessionModel(store: MemoryStore(), catalog: catalog, queue: ["A1-01"])
        gradeCurrent(s, .again)                          // Опять → due today
        s.reveal()
        #expect(Set(s.captions.values) == ["сегодня"])
    }
}
