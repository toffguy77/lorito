import Testing
import Foundation
@testable import Domain

private let utc: Calendar = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)

/// Exercise `n` of `level`, theme `<level>-<theme>`, card `<LEVEL>-<card>`.
private func ex(_ level: CEFRLevel, _ n: Int, theme: Int, card: Int? = nil,
                kind: ExerciseKind = .multipleChoice(options: ["a", "b"], answer: "a")) -> Exercise {
    let L = level.rawValue
    return Exercise(id: "\(L)-EX-\(String(format: "%02d", n))", level: level, themeID: "\(L.lowercased())-\(theme)",
                    card: "\(L)-\(String(format: "%02d", card ?? n))", prompt: "?", explanation: "", kind: kind)
}

/// Six auto-checkable exercises per level over three themes, plus noise the test must skip.
private let pool: [Exercise] = CEFRLevel.allCases.flatMap { level in
    (1...6).map { ex(level, $0, theme: ($0 - 1) % 3 + 1) } + [
        ex(level, 50, theme: 1, kind: .fillInTheBlank(answer: "a", accept: [])),
        ex(level, 51, theme: 1, kind: .freeResponse(answer: "a", accept: [])),
        ex(level, 52, theme: 2, kind: .wordOrder(tokens: ["a", "b"], answer: "a b", accept: [])),
    ]
}

/// Runs the test with scripted per-level answers (`true` = correct), returning the history.
private func run(_ script: [CEFRLevel: [Bool]], seed: UInt64 = 7, exercises: [Exercise] = pool) -> [PlacementAnswer] {
    var history: [PlacementAnswer] = []
    var used: [CEFRLevel: Int] = [:]
    while let next = PlacementTest.next(exercises: exercises, seed: seed, history: history) {
        let i = used[next.level, default: 0]
        used[next.level] = i + 1
        let correct = script[next.level].map { i < $0.count ? $0[i] : false } ?? false
        history.append(PlacementAnswer(exercise: next, correct: correct))
        if history.count > 40 { break }
    }
    return history
}

@Suite("Placement test: blocks")
struct PlacementBlockTests {
    @Test("Three per level, A2 first, distinct themes, only fast auto-checked types, no repeats")
    func blocks() {
        let h = run([.a2: [true, true, true], .b1: [false, false, false]])
        #expect(h.first?.level == .a2)
        let a2 = h.filter { $0.level == .a2 }
        #expect(a2.count == PlacementConstants.itemsPerLevel)
        #expect(Set(a2.map(\.themeID)).count == 3)
        #expect(Set(h.map(\.exerciseID)).count == h.count)
        let allowed = Set(pool.filter { PlacementTest.isEligible($0) }.map(\.id))
        #expect(h.allSatisfy { allowed.contains($0.exerciseID) })
        #expect(!h.contains { $0.exerciseID.hasSuffix("-50") || $0.exerciseID.hasSuffix("-51") })
    }

    @Test("No early stop inside a block: a wrong first answer still gets the other two")
    func fullBlock() {
        let h = run([.a2: [false, true, true]])
        #expect(h.filter { $0.level == .a2 }.count == 3)
    }

    @Test("Same pool, seed and history → same next exercise; another seed may differ")
    func deterministic() {
        let a = PlacementTest.next(exercises: pool, seed: 1, history: [])
        let b = PlacementTest.next(exercises: pool.reversed(), seed: 1, history: [])
        #expect(a == b)
        #expect(run([.a2: [true, true, true]], seed: 3) == run([.a2: [true, true, true]], seed: 3))
    }
}

@Suite("Placement test: pass and stop")
struct PlacementStopTests {
    @Test("2 of 3 passes and climbs to B1")
    func climb() {
        let h = run([.a2: [true, false, true], .b1: [false, false, false]])
        #expect(h.map(\.level) == [.a2, .a2, .a2, .b1, .b1, .b1])
    }

    @Test("Stop after a failed level")
    func stopAfterFail() {
        let h = run([.a2: [true, true, true], .b1: [true, false, false]])
        #expect(h.count == 6 && h.last?.level == .b1)
    }

    @Test("All passed: stops after C2 (five blocks, 15 questions)")
    func allPassed() {
        let all = Dictionary(uniqueKeysWithValues: CEFRLevel.allCases.map { ($0, [true, true, true]) })
        let h = run(all)
        #expect(h.count == 15 && h.last?.level == .c2)
        #expect(!h.contains { $0.level == .a1 })
    }

    @Test("A2 failed → one A1 block, then stop (even if A1 passes)")
    func a2Failed() {
        let h = run([.a2: [true, false, false], .a1: [true, true, true]])
        #expect(h.map(\.level) == [.a2, .a2, .a2, .a1, .a1, .a1])
    }

    @Test("Level with < 2 usable exercises is untestable: the test stops below it")
    func untestable() {
        let thin = pool.filter { $0.level != .b2 || $0.id == "B2-EX-01" }
        let h = run([.a2: [true, true, true], .b1: [true, true, true], .b2: [true, true, true]], exercises: thin)
        #expect(!h.contains { $0.level == .b2 })
        let r = PlacementTest.result(history: h)
        #expect(r.highestKnown == .b1 && r.proposedTarget == .b2)
    }

    @Test("Two usable exercises: block of two, threshold still 2")
    func twoUsable() {
        let two = pool.filter { $0.level != .a2 || ["A2-EX-01", "A2-EX-02"].contains($0.id) }
        let h = run([.a2: [true, true], .b1: [false, false, false]], exercises: two)
        #expect(h.filter { $0.level == .a2 }.count == 2)
        #expect(h.contains { $0.level == .b1 })
    }
}

@Suite("Placement test: result")
struct PlacementResultTests {
    @Test("A2 3/3 + B1 1/3 → target B1, known A1–A2, 6 questions")
    func b1() {
        let r = PlacementTest.result(history: run([.a2: [true, true, true], .b1: [true, false, false]]))
        #expect(r.proposedTarget == .b1 && r.highestKnown == .a2)
        #expect(r.knownLevels == [.a1, .a2] && r.questionCount == 6)
    }

    @Test("Nothing passed → A1, no known levels")
    func nothing() {
        let r = PlacementTest.result(history: run([:]))
        #expect(r.proposedTarget == .a1 && r.highestKnown == nil && r.knownLevels.isEmpty)
    }

    @Test("A2 failed, A1 passed → target A2, known A1")
    func a1Only() {
        let r = PlacementTest.result(history: run([.a2: [false, false, true], .a1: [true, true, false]]))
        #expect(r.proposedTarget == .a2 && r.highestKnown == .a1)
    }

    @Test("C2 passed → C2, every level known")
    func c2() {
        let all = Dictionary(uniqueKeysWithValues: CEFRLevel.allCases.map { ($0, [true, true, true]) })
        let r = PlacementTest.result(history: run(all))
        #expect(r.proposedTarget == .c2 && r.highestKnown == .c2 && r.knownLevels == CEFRLevel.allCases)
    }
}

@Suite("Placement test: traps and seeding")
struct PlacementTrapSeedTests {
    static func card(_ id: String, level: CEFRLevel, mistakes: String?) -> Card {
        let body = "> **Суть**\n> Текст.\n\n" + (mistakes.map { "## ⚠️ Частые ошибки (для русскоязычных)\n- \($0)\n- второе\n" } ?? "")
        return Card(id: id, level: level, themeID: "\(level.rawValue.lowercased())-1", order: 1, title: id, body: body)
    }

    let catalog = ContentCatalog(themes: [], cards: [
        card("A1-07", level: .a1, mistakes: "*el problema* — мужского рода"),
        card("A1-09", level: .a1, mistakes: "Артикль перед профессией"),
        card("A1-10", level: .a1, mistakes: nil),
        card("A1-11", level: .a1, mistakes: "Четвёртая"),
        card("A1-12", level: .a1, mistakes: "Пятая"),
    ])

    func answer(_ card: String, _ correct: Bool, level: CEFRLevel = .a1) -> PlacementAnswer {
        PlacementAnswer(exerciseID: card + "-x", level: level, themeID: "t", cardID: card, correct: correct)
    }

    @Test("First mistakes item per failed card, one per card, newest first, max 3, skipping cards without one")
    func traps() {
        let h = [answer("A1-07", false), answer("A1-09", false), answer("A1-10", false), answer("A1-07", false),
                 answer("A1-11", true), answer("A1-12", false), answer("A1-11", false)]
        let traps = PlacementTest.traps(history: h, catalog: catalog)
        #expect(traps.map(\.cardID) == ["A1-11", "A1-12", "A1-07"])
        #expect(traps.last?.text == "*el problema* — мужского рода")
        #expect(PlacementTest.traps(history: [answer("A1-10", false)], catalog: catalog).isEmpty)
    }

    @Test("Seeding: only correctly answered cards at known levels, state = scheduler(new, Хорошо, today)")
    func seeding() {
        let today = utc.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 9))!
        let h = [answer("A1-07", true), answer("A1-09", false), answer("A1-07", true),
                 answer("A2-03", true, level: .a2), answer("B1-01", true, level: .b1)]
        let result = PlacementResult(proposedTarget: .b1, highestKnown: .a2, questionCount: h.count)
        let seeded = PlacementTest.seedReviews(history: h, result: result, today: today, calendar: utc)
        #expect(seeded.map(\.cardID) == ["A1-07", "A2-03"])
        let expected = FSRSScheduler.schedule(state: ReviewState(cardID: "A1-07"), grade: .good, today: today, calendar: utc)
        #expect(seeded.first == expected)
        #expect(PlacementTest.seedReviews(history: h, result: PlacementResult(proposedTarget: .a1, highestKnown: nil,
                                                                           questionCount: 5), today: today, calendar: utc).isEmpty)
    }
}
