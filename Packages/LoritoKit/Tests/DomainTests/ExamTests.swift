import Testing
import Foundation
@testable import Domain

/// DELE-like definition: four sections of 25 points in two groups (pass 30/50 each).
private let deleDef = ExamDefinition(
    id: "dele-a2", title: "DELE A2", verifiedOn: "2026-10-27",
    sections: [
        ExamSection(id: "reading", title: "Чтение", minutes: 60, maxPoints: 25, productive: false),
        ExamSection(id: "listening", title: "Аудирование", minutes: 40, maxPoints: 25, productive: false),
        ExamSection(id: "writing", title: "Письмо", minutes: 45, maxPoints: 25, productive: true),
        ExamSection(id: "speaking", title: "Говорение", minutes: 12, maxPoints: 25, productive: true, prepMinutes: 12),
    ],
    groups: [ScoreGroup(id: "g1", title: "Группа 1", sections: ["reading", "writing"], passPoints: 30),
             ScoreGroup(id: "g2", title: "Группа 2", sections: ["listening", "speaking"], passPoints: 30)])

private let ccseDef = ExamDefinition(
    id: "ccse", title: "CCSE", verifiedOn: "2026-10-27",
    sections: [ExamSection(id: "ccse", title: "CCSE", minutes: 45, maxPoints: 25, productive: false)],
    groups: [ScoreGroup(id: "all", title: "Итог", sections: ["ccse"], passPoints: 15)])

private func choiceItems(_ section: String, _ n: Int, points: Double = 1) -> [ExamItem] {
    (0..<n).map { ExamItem(id: "\(section)-\($0)", exam: "x", section: section, points: points,
                           kind: .choice(options: ["a", "b"], answer: "a")) }
}

@Suite("Mock scoring")
struct MockScorerTests {
    @Test("Group scaling: 38/50 and 28/50 fails on Group 2; 30/30 passes")
    func dele() {
        // Raw sections scaled to 25: reading 19/25, writing 19/25 → G1 38; listening 14, speaking 14 → G2 28.
        let items = choiceItems("reading", 25) + choiceItems("listening", 25)
        let raw: [String: Double] = ["reading": 19, "writing": 19, "listening": 14, "speaking": 14]
        let r = MockScorer.score(deleDef, sectionPoints: raw)
        #expect(!r.passed && r.failingGroups == ["g2"])
        #expect(r.groupPoints["g1"] == 38 && r.groupPoints["g2"] == 28)
        let pass = MockScorer.score(deleDef, sectionPoints: ["reading": 15, "writing": 15, "listening": 15, "speaking": 15])
        #expect(pass.passed && pass.failingGroups.isEmpty)
        // From answers: correct share scaled to the section maximum; unanswered = incorrect.
        let answers = Dictionary(uniqueKeysWithValues: items.prefix(20).map { ($0.id, "a") })
        let points = MockScorer.sectionPoints(deleDef, items: items, answers: answers, rubricPoints: [:])
        #expect(points["reading"] == 20 && points["listening"] == 0)
    }

    @Test("CCSE: 15/25 passes, 14/25 fails, unanswered counted incorrect")
    func ccseScore() {
        let items = choiceItems("ccse", 25)
        func result(_ correct: Int) -> MockResult {
            let answers = Dictionary(uniqueKeysWithValues: items.prefix(correct).map { ($0.id, "a") })
            return MockScorer.score(ccseDef, sectionPoints: MockScorer.sectionPoints(ccseDef, items: items, answers: answers, rubricPoints: [:]))
        }
        #expect(result(15).passed)
        #expect(!result(14).passed)
    }
}

@Suite("Rubric, timer, readiness, CCSE quota")
struct ExamSupportTests {
    @Test("Rubric: four of six items worth 2 → 8 points, self-assessed")
    func rubric() {
        let rubric = (0..<6).map { RubricItem(text: "критерий \($0)", points: 2) }
        let s = RubricScore(rubric: rubric, ticked: [0, 1, 3, 5])
        #expect(s.points == 8 && s.isSelfAssessed)
    }

    @Test("Timer: remaining from persisted start + injected now; expiry")
    func timer() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        #expect(MockTimer.remaining(minutes: 45, startedAt: start, now: start.addingTimeInterval(600)) == 35 * 60)
        #expect(MockTimer.remaining(minutes: 45, startedAt: start, now: start.addingTimeInterval(46 * 60)) == 0)
        #expect(MockTimer.isExpired(minutes: 45, startedAt: start, now: start.addingTimeInterval(45 * 60)))
    }

    @Test("Readiness: deterministic labels; productive part missing caps at «На грани»; abandoned excluded")
    func readiness() {
        let good = MockRecord(examID: "dele-a2", completed: true, abandoned: false,
                              sectionFractions: ["reading": 0.9, "writing": 0.9, "listening": 0.9])
        let abandoned = MockRecord(examID: "dele-a2", completed: false, abandoned: true,
                                   sectionFractions: ["speaking": 0.1])
        let r = ReadinessCalculator.dele(deleDef, mocks: [good, good, abandoned], cardMastery: 0.9)
        #expect(r["g1"] == .likely)
        #expect(r["g2"] == .borderline)                 // no speaking attempt
        let weak = MockRecord(examID: "dele-a2", completed: true, abandoned: false,
                              sectionFractions: ["reading": 0.3, "writing": 0.3, "listening": 0.3, "speaking": 0.3])
        #expect(ReadinessCalculator.dele(deleDef, mocks: [weak], cardMastery: 0.2)["g1"] == .tooEarly)
        #expect(ReadinessLabel.likely.title == "Скорее сдадите" && ReadinessLabel.tooEarly.title == "Пока рано")
        #expect(ReadinessCalculator.ccse(mocks: [], itemMastery: 0.95) == ReadinessCalculator.ccse(mocks: [], itemMastery: 0.95))
    }

    @Test("CCSE quota: never above ccseDailyNewLimit within the shared budget; 0 disables")
    func quota() {
        let budget = DailyBudget(total: 12, quotas: [.ccse: 5])
        #expect(budget.allowances(introducedToday: [:])[.ccse] == 5)
        var s = UserSettings()
        #expect(s.ccseDailyNewLimit == 5)
        s.ccseDailyNewLimit = 0
        #expect(DailyBudget.standard(settings: s).allowances(introducedToday: [:])[.ccse] == 0)
    }
}

@Suite("Exam content decoding")
struct ExamDecodingTests {
    @Test("Definitions and items (choice, listening, writing, speaking) decode from the bundle shape")
    func decode() throws {
        let json = #"""
        {"themes": [], "cards": [], "exams": {
          "definitions": [{"id": "ccse", "title": "CCSE", "verifiedOn": "2026-10-27",
            "sections": [{"id": "ccse", "title": "CCSE", "minutes": 45, "maxPoints": 25, "productive": false}],
            "groups": [{"id": "all", "title": "Итог", "sections": ["ccse"], "passPoints": 15}]}],
          "items": [
            {"id": "ccse-1", "exam": "ccse", "section": "ccse", "points": 1, "kind": {"choice": {"options": ["a", "b"], "answer": "a"}},
             "text": "¿?", "explanation": "", "form": 1, "preview": true, "cards": [], "retired": false, "source": "cervantes-ccse", "edition": "2026"},
            {"id": "l1", "exam": "dele-a2", "section": "listening", "points": 1,
             "kind": {"listeningTask": {"script": "Hola", "options": ["a", "b"], "answer": "b"}},
             "text": "", "explanation": "", "form": 1, "preview": false, "cards": ["A1-01"], "retired": false},
            {"id": "w1", "exam": "dele-a2", "section": "writing", "points": 1,
             "kind": {"writingTask": {"prompt": "Escribe", "rubric": [{"text": "x", "points": 2}]}},
             "text": "", "explanation": "", "form": 1, "preview": false, "cards": [], "retired": false},
            {"id": "s1", "exam": "dele-a2", "section": "speaking", "points": 1,
             "kind": {"speakingTask": {"prompt": "Habla", "prepSeconds": 120, "rubric": [{"text": "x", "points": 2}]}},
             "text": "", "explanation": "", "form": 2, "preview": false, "cards": [], "retired": false}
          ]}}
        """#
        let c = try JSONDecoder().decode(ContentCatalog.self, from: Data(json.utf8))
        let exams = try #require(c.exams)
        #expect(exams.definition("ccse")?.groups.first?.passPoints == 15)
        #expect(exams.items.count == 4 && exams.items[0].correctAnswer == "a" && exams.items[1].correctAnswer == "b")
        #expect(exams.items[2].isProductive && exams.items[3].rubric.count == 1)
        #expect(exams.isPreview(exam: "ccse", form: 1) && exams.forms(exam: "dele-a2") == [1, 2])
    }
}

@Suite("Mock attempts")
struct MockAttemptTests {
    let items = (0..<25).map { ExamItem(id: "q\($0)", exam: "ccse", section: "ccse", kind: .choice(options: ["a", "b"], answer: "a")) }

    @Test("Closing after 45 minutes away scores with unanswered counted incorrect")
    func expiry() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        var a = MockAttempt(examID: "ccse", form: 1, startedAt: start)
        for i in 0..<15 { a.answers["q\(i)"] = "a" }
        #expect(MockRun.closeIfExpired(a, def: ccseDef, items: items, now: start.addingTimeInterval(44 * 60)).state == .inProgress)
        let closed = MockRun.closeIfExpired(a, def: ccseDef, items: items, now: start.addingTimeInterval(45 * 60 + 1))
        #expect(closed.state == .completed && closed.expired)
        #expect(MockRun.result(closed, def: ccseDef).passed)                // 15/25
    }

    @Test("Sections advance in order with their own start; the last one completes")
    func sections() {
        let start = Date(timeIntervalSince1970: 3_000_000)
        var a = MockAttempt(examID: "dele-a2", form: 1, startedAt: start)
        a = MockRun.submitSection(a, def: deleDef, items: [], now: start.addingTimeInterval(600))
        #expect(a.sectionIndex == 1 && a.sectionStartedAt == start.addingTimeInterval(600))
        for _ in 0..<3 { a = MockRun.submitSection(a, def: deleDef, items: [], now: start.addingTimeInterval(1200)) }
        #expect(a.state == .completed && !MockRun.result(a, def: deleDef).passed)
    }
}

@Suite("CCSE spaced repetition")
struct CCSEPlannerTests {
    let bank = (1...30).map { ExamItem(id: "ccse-\($0)", exam: "ccse", section: "ccse",
                                        kind: .choice(options: ["a", "b"], answer: "a"), retired: $0 == 2) }

    @Test("Spec: limit 5 while the budget allows more → at most 5 new; 0 disables; retired never")
    func quota() {
        var s = UserSettings(dailyNewCardCount: 1)
        let plan = CCSEPlanner.plan(bank: bank, reviews: [], settings: s, introducedToday: [:], today: Date())
        #expect(plan == ["ccse:ccse-1", "ccse:ccse-3", "ccse:ccse-4", "ccse:ccse-5", "ccse:ccse-6"])
        s.ccseDailyNewLimit = 0
        #expect(CCSEPlanner.plan(bank: bank, reviews: [], settings: s, introducedToday: [:], today: Date()).isEmpty)
        #expect(ItemKind.parse("ccse:ccse-1") == .ccse)
    }
}
