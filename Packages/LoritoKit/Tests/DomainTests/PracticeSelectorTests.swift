import Testing
import Foundation
@testable import Domain

private func ex(_ id: String, card: String, level: CEFRLevel = .a1, theme: String = "a1-1") -> Exercise {
    Exercise(id: id, level: level, themeID: theme, card: card, prompt: "P", explanation: "E",
             kind: .multipleChoice(options: ["a", "b"], answer: "a"))
}

private func card(_ id: String, order: Int, level: CEFRLevel = .a1, theme: String = "a1-1") -> Card {
    Card(id: id, level: level, themeID: theme, order: order, title: id, body: "")
}

private func studied(_ id: String) -> ReviewState {
    ReviewState(cardID: id, interval: 3, repetitions: 1, lastGrade: "good", status: .review)
}

private func attempt(_ exID: String, card: String, at t: TimeInterval, correct: Bool) -> ExerciseAttempt {
    ExerciseAttempt(exerciseID: exID, cardID: card, date: Date(timeIntervalSince1970: t), correct: correct)
}

/// Theme a1-1: A1-01, A1-02 (3 exercises each); theme a2-1: A2-01 with 30 exercises.
private let catalog: ContentCatalog = {
    let cards = [card("A1-01", order: 1), card("A1-02", order: 2),
                 card("A2-01", order: 1, level: .a2, theme: "a2-1")]
    var exercises: [Exercise] = []
    for c in ["A1-01", "A1-02"] { for i in 1...3 { exercises.append(ex("\(c)-EX-\(i)", card: c)) } }
    for i in 1...30 { exercises.append(ex("A2-01-EX-\(i)", card: "A2-01", level: .a2, theme: "a2-1")) }
    return ContentCatalog(themes: [Theme(id: "a1-1", level: .a1, title: "T", order: 1),
                                   Theme(id: "a2-1", level: .a2, title: "T2", order: 1)],
                          cards: cards, exercises: exercises)
}()

@Suite("Practice selector")
struct PracticeSelectorTests {
    @Test("Only studied cards are eligible; new cards never appear in any mode")
    func onlyStudied() {
        let reviews = ["A1-01": studied("A1-01"), "A1-02": ReviewState(cardID: "A1-02")]
        let misses = [attempt("A1-02-EX-1", card: "A1-02", at: 10, correct: false),
                      attempt("A1-01-EX-1", card: "A1-01", at: 5, correct: false)]
        for mode in [PracticeMode.mixed, .weakSpots, .theme("a1-1"), .level(.a1)] {
            let picked = PracticeSelector.select(mode, catalog: catalog, reviews: reviews, attempts: misses, seed: 1)
            #expect(!picked.isEmpty)
            #expect(picked.allSatisfy { $0.card == "A1-01" })
        }
    }

    @Test("A suspended card counts as studied only after it was graded")
    func suspended() {
        var graded = studied("A1-01"); graded.status = .suspended
        #expect(PracticeSelector.isStudied(graded))
        #expect(!PracticeSelector.isStudied(ReviewState(cardID: "A1-02", status: .suspended)))
        #expect(!PracticeSelector.isStudied(nil))
    }

    @Test("Mixed: capped at 20, never-attempted first, then least recently attempted; deterministic")
    func mixed() {
        let reviews = ["A2-01": studied("A2-01")]
        // 20 of the 30 attempted; ids 1…20 at times 1…20 (EX-1 oldest).
        let attempts = (1...20).map { attempt("A2-01-EX-\($0)", card: "A2-01", at: TimeInterval($0), correct: true) }
        let picked = PracticeSelector.select(.mixed, catalog: catalog, reviews: reviews, attempts: attempts, seed: 7)
        #expect(picked.count == 20)
        let ids = Set(picked.map(\.id))
        #expect((21...30).allSatisfy { ids.contains("A2-01-EX-\($0)") })     // all 10 unseen
        #expect((1...10).allSatisfy { ids.contains("A2-01-EX-\($0)") })      // then the 10 oldest
        let again = PracticeSelector.select(.mixed, catalog: catalog, reviews: reviews, attempts: attempts, seed: 7)
        #expect(again.map(\.id) == picked.map(\.id))
    }

    @Test("Mixed: two exercises of the same card are not adjacent when another choice exists")
    func spread() {
        let reviews = ["A1-01": studied("A1-01"), "A1-02": studied("A1-02")]
        let picked = PracticeSelector.select(.mixed, catalog: catalog, reviews: reviews, attempts: [], seed: 3)
        #expect(picked.count == 6)
        #expect(zip(picked, picked.dropFirst()).allSatisfy { $0.card != $1.card })
    }

    @Test("Weak spots: last attempt wrong, most recent miss first; a later correct answer removes it")
    func weak() {
        let reviews = ["A1-01": studied("A1-01"), "A1-02": studied("A1-02")]
        let attempts = [
            attempt("A1-01-EX-1", card: "A1-01", at: 10, correct: false),
            attempt("A1-01-EX-2", card: "A1-01", at: 30, correct: false),
            attempt("A1-02-EX-1", card: "A1-02", at: 20, correct: false),
            attempt("A1-02-EX-1", card: "A1-02", at: 40, correct: true),   // fixed later
            attempt("A1-02-EX-2", card: "A1-02", at: 50, correct: true),
        ]
        let picked = PracticeSelector.select(.weakSpots, catalog: catalog, reviews: reviews, attempts: attempts, seed: 1)
        #expect(picked.map(\.id) == ["A1-01-EX-2", "A1-01-EX-1"])
    }

    @Test("Weak spots capped at 20")
    func weakCap() {
        let reviews = ["A2-01": studied("A2-01")]
        let attempts = (1...30).map { attempt("A2-01-EX-\($0)", card: "A2-01", at: TimeInterval($0), correct: false) }
        #expect(PracticeSelector.select(.weakSpots, catalog: catalog, reviews: reviews, attempts: attempts, seed: 1).count == 20)
    }

    @Test("Theme: every eligible exercise in card order; level: capped at 20 and only that level")
    func themeAndLevel() {
        let reviews = ["A1-01": studied("A1-01"), "A1-02": studied("A1-02"), "A2-01": studied("A2-01")]
        let theme = PracticeSelector.select(.theme("a1-1"), catalog: catalog, reviews: reviews, attempts: [], seed: 1)
        #expect(theme.map(\.id) == ["A1-01-EX-1", "A1-01-EX-2", "A1-01-EX-3", "A1-02-EX-1", "A1-02-EX-2", "A1-02-EX-3"])
        let level = PracticeSelector.select(.level(.a2), catalog: catalog, reviews: reviews, attempts: [], seed: 1)
        #expect(level.count == 20)
        #expect(level.allSatisfy { $0.level == .a2 })
    }

    @Test("Availability: «доступно X из Y» for theme, level, catalog and weak spots")
    func availability() {
        let reviews = ["A1-01": studied("A1-01")]
        let misses = [attempt("A1-01-EX-1", card: "A1-01", at: 1, correct: false),
                      attempt("A1-02-EX-1", card: "A1-02", at: 2, correct: false)]
        func avail(_ m: PracticeMode) -> PracticeAvailability {
            PracticeSelector.availability(m, catalog: catalog, reviews: reviews, attempts: misses)
        }
        #expect(avail(.theme("a1-1")) == PracticeAvailability(available: 3, total: 6))
        #expect(avail(.level(.a2)) == PracticeAvailability(available: 0, total: 30))
        #expect(avail(.mixed) == PracticeAvailability(available: 3, total: 36))
        #expect(avail(.weakSpots) == PracticeAvailability(available: 1, total: 2))
    }
}
