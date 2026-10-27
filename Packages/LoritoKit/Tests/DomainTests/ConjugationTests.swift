import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private let today = cal.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 10))!
private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: today)! }

private let bundleJSON = """
{"themes": [], "cards": [], "exercises": [],
 "conjugation": {
  "tenses": [
   {"id": "presente", "es": "Presente", "ru": "Настоящее", "mood": "indicativo", "level": "A1", "card": "A1-19", "order": 1},
   {"id": "preterito-indefinido", "es": "Indefinido", "ru": "Прошедшее", "mood": "indicativo", "level": "A2", "card": "A2-02", "order": 3}
  ],
  "verbs": [
   {"infinitive": "ser", "rank": 2, "ru": "быть", "reflexive": false,
    "paradigms": {"presente": ["soy","eres","es","somos","sois","son"], "preterito-indefinido": ["fui","fuiste","fue","fuimos","fuisteis","fueron"]}},
   {"infinitive": "hablar", "rank": 9, "ru": "говорить", "reflexive": false,
    "paradigms": {"presente": ["hablo","hablas","habla","hablamos","habláis","hablan"], "preterito-indefinido": ["hablé","hablaste","habló","hablamos","hablasteis","hablaron"]}},
   {"infinitive": "levantarse", "rank": 50, "ru": "вставать", "reflexive": true,
    "paradigms": {"presente": ["me levanto","te levantas","se levanta","nos levantamos","os levantáis","se levantan"], "preterito-indefinido": ["me levanté","te levantaste","se levantó","nos levantamos","os levantasteis","se levantaron"]}}
  ]}}
"""

private let catalog: ContentCatalog = try! JSONDecoder().decode(ContentCatalog.self, from: Data(bundleJSON.utf8))
private var conj: ConjugationCatalog { catalog.conjugation! }
private let cards = [
    Card(id: "A1-19", level: .a1, themeID: "a1-4", order: 19, title: "Presente", body: ""),
    Card(id: "A2-02", level: .a2, themeID: "a2-1", order: 2, title: "Indefinido", body: ""),
]

@Suite("Conjugation model")
struct ConjugationModelTests {
    @Test("Types decode from the bundle; item id is conj:<infinitive>:<tense-id>")
    func decode() {
        #expect(conj.tenses.map(\.id) == ["presente", "preterito-indefinido"])
        #expect(conj.verbs.first?.infinitive == "ser" && conj.verbs[2].reflexive)
        let item = ConjugationItem(verb: conj.verbs[1], tense: conj.tenses[0])
        #expect(item.id == "conj:hablar:presente")
        #expect(item.forms == ["hablo", "hablas", "habla", "hablamos", "habláis", "hablan"])
        #expect(ItemKind.parse(item.id) == .conjugation)
        #expect(ConjugationItem.parse("conj:hablar:presente")! == ("hablar", "presente"))
    }

    @Test("A bundle without conjugation decodes as nil")
    func absent() throws {
        let c = try JSONDecoder().decode(ContentCatalog.self, from: Data(#"{"themes":[],"cards":[]}"#.utf8))
        #expect(c.conjugation == nil)
    }
}

@Suite("Tense unlocking")
struct TenseUnlockTests {
    @Test("Locked until the mapped card is studied and its level included")
    func unlock() {
        let a1 = UserSettings(targetLevel: .a1)
        let a2 = UserSettings(targetLevel: .a2)
        #expect(ConjugationUnlock.unlockedTenses(conj, cards: cards, reviews: [], settings: a2).isEmpty)
        let studied = [ReviewState(cardID: "A1-19", status: .review), ReviewState(cardID: "A2-02", status: .review)]
        #expect(ConjugationUnlock.unlockedTenses(conj, cards: cards, reviews: studied, settings: a1).map(\.id) == ["presente"])
        #expect(ConjugationUnlock.unlockedTenses(conj, cards: cards, reviews: studied, settings: a2).map(\.id)
                == ["presente", "preterito-indefinido"])
    }
}

@Suite("Conjugation planner")
struct ConjugationPlannerTests {
    let unlocked = Array(conj.tenses)

    func due(_ id: String, _ d: Int) -> ReviewState {
        ReviewState(cardID: id, interval: 3, repetitions: 1, dueDate: day(d), status: .review)
    }

    @Test("Due cap 20: most overdue first, then id; the rest wait")
    func cap() {
        let reviews = (0..<45).map { due("conj:v\(String(format: "%02d", $0)):presente", -($0 % 5)) }
        let plan = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: reviews, events: [], quota: 0,
                                           introducedToday: [:], today: today, calendar: cal)
        #expect(plan.due.count == 20)
        #expect(plan.due.first == "conj:v04:presente")          // 4 days overdue, lowest id
        #expect(plan.new.isEmpty)
    }

    @Test("New items by rank within the earliest unlocked tense; quota and budget respected; off by default")
    func newItems() {
        let p = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [], events: [], quota: 3,
                                        introducedToday: [:], today: today, calendar: cal)
        #expect(p.new == ["conj:ser:presente", "conj:hablar:presente", "conj:levantarse:presente"])
        let off = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [], events: [], quota: 0,
                                          introducedToday: [:], today: today, calendar: cal)
        #expect(off.new.isEmpty)
        // Combined budget: 9 cards already introduced today leave room for 1.
        let tight = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [], events: [], quota: 3,
                                            introducedToday: [.card: 9], today: today, calendar: cal)
        #expect(tight.new.count == 1)
        // Spent quota: one conj item already introduced today.
        let spent = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [], events: [], quota: 3,
                                            introducedToday: [.conjugation: 2], today: today, calendar: cal)
        #expect(spent.new.count == 1)
    }

    @Test("Deterministic for identical inputs")
    func deterministic() {
        let a = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [due("conj:ser:presente", -1)], events: [],
                                        quota: 3, introducedToday: [:], today: today, calendar: cal)
        let b = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: [due("conj:ser:presente", -1)], events: [],
                                        quota: 3, introducedToday: [:], today: today, calendar: cal)
        #expect(a == b)
        #expect(!a.new.contains("conj:ser:presente"))
    }

    @Test("A due conj: review never enters the card queue or counts")
    func notInCardQueue() {
        let plan = DailyPlanner.composePlan(DailyPlanRequest(cards: cards, reviews: [due("conj:ser:presente", -1)],
                                                             settings: UserSettings(targetLevel: .a1), today: today,
                                                             calendar: cal))
        #expect(!plan.queue.contains { $0.cardID.hasPrefix("conj:") } && plan.counts.dueCount == 0)
    }
}

@Suite("Person rotation")
struct PersonRotationTests {
    let spain = PersonRotation.spain

    @Test("Three reviews cover all six Spain persons; rotation survives a lapse (event-count based)")
    func rotation() {
        let asked = (0..<3).flatMap { PersonRotation.persons(itemID: "conj:hablar:presente", gradedCount: $0, personSet: spain) }
        #expect(Set(asked).count == 6)
        let third = PersonRotation.persons(itemID: "conj:hablar:presente", gradedCount: 2, personSet: spain)
        let firstTwo = (0..<2).flatMap { PersonRotation.persons(itemID: "conj:hablar:presente", gradedCount: $0, personSet: spain) }
        #expect(Set(third).isDisjoint(with: firstTwo))
        // Graded events for the item (any grade) drive the count.
        let events = [StudyEvent(cardID: "conj:hablar:presente", date: day(-3), grade: "good"),
                      StudyEvent(cardID: "conj:hablar:presente", date: day(-1), grade: "again"),
                      StudyEvent(cardID: "conj:ser:presente", date: day(-1), grade: "good")]
        #expect(PersonRotation.gradedCount(itemID: "conj:hablar:presente", events: events) == 2)
    }

    @Test("Person set is an input (no vosotros in Latin America)")
    func injected() {
        let latam = [0, 1, 2, 3, 5]
        let asked = (0..<5).flatMap { PersonRotation.persons(itemID: "conj:ser:presente", gradedCount: $0, personSet: latam) }
        #expect(!asked.contains(4))
    }

    @Test("Worse answer decides")
    func worse() {
        #expect(ConjugationChecker.combined([.good, .again]) == .again)
        #expect(ConjugationChecker.combined([.good, .hard]) == .hard)
        #expect(ConjugationChecker.combined([.good, .good]) == .good)
    }
}

@Suite("Conjugation checker")
struct ConjugationCheckerTests {
    @Test("Exact (trimmed, case-insensitive) → Хорошо")
    func exact() {
        let r = ConjugationChecker.check(expected: "habló", typed: "Habló ")
        #expect(r.verdict == .correct && r.grade == .good)
    }

    @Test("Accent-only difference → почти, Трудно, accented form shown")
    func accent() {
        let r = ConjugationChecker.check(expected: "habló", typed: "hablo")
        #expect(r.verdict == .almost && r.grade == .hard && r.expected == "habló")
        #expect(ConjugationChecker.check(expected: "niño", typed: "nino").verdict == .almost)
    }

    @Test("Wrong form → Опять, expected shown")
    func wrong() {
        let r = ConjugationChecker.check(expected: "habló", typed: "hablé")
        #expect(r.verdict == .wrong && r.grade == .again && r.expected == "habló")
    }

    @Test("Reflexive: pronoun required; missing/wrong pronoun → почти, Трудно")
    func reflexive() {
        #expect(ConjugationChecker.check(expected: "me levanto", typed: "me levanto", reflexive: true).verdict == .correct)
        let missing = ConjugationChecker.check(expected: "me levanto", typed: "levanto", reflexive: true)
        #expect(missing.verdict == .almost && missing.grade == .hard && missing.expected == "me levanto")
        #expect(ConjugationChecker.check(expected: "me levanto", typed: "te levanto", reflexive: true).verdict == .almost)
        #expect(ConjugationChecker.check(expected: "me he levantado", typed: "he levantado", reflexive: true).verdict == .almost)
        #expect(ConjugationChecker.check(expected: "me levanto", typed: "me levanté", reflexive: true).verdict == .wrong)
    }
}
