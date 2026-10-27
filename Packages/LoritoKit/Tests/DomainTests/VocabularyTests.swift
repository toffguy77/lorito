import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private let today = cal.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 10))!
private func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: today)! }

private let json = #"""
{"decks": [
  {"id": "a1-casa", "level": "A1", "title_ru": "Дом", "order": 1, "words": [
    {"id": "casa", "es": "casa", "pos": "noun", "article": "la", "gender": "f", "ru": "дом", "example_es": "Mi casa es pequeña.", "example_ru": "Мой дом маленький.", "rank": 120, "forms": ["casas"]},
    {"id": "estudiante", "es": "estudiante", "pos": "noun", "article": "el", "gender": "mf", "ru": "студент", "example_es": "Soy estudiante.", "example_ru": "Я студент.", "rank": 900, "forms": []},
    {"id": "comer", "es": "comer", "pos": "verb", "ru": "есть", "example_es": "Vamos a comer.", "example_ru": "Пойдём поедим.", "rank": 300, "forms": ["como", "comes", "comió"]}
  ]},
  {"id": "a2-viaje", "level": "A2", "title_ru": "Путешествия", "order": 1, "words": [
    {"id": "viaje", "es": "viaje", "pos": "noun", "article": "el", "gender": "m", "ru": "поездка", "example_es": "Buen viaje.", "example_ru": "Счастливого пути.", "rank": 700, "forms": []}
  ]}
]}
"""#
private let vocab = try! JSONDecoder().decode(VocabularyCatalog.self, from: Data(json.utf8))
private func ev(_ id: String, _ g: Grade, _ d: Int) -> StudyEvent { StudyEvent(cardID: id, date: day(d), grade: g.rawValue) }

@Suite("Vocabulary")
struct VocabularyTests {
    @Test("Decks and words decode; deck order then rank; item ids word:<lemma>")
    func decode() {
        #expect(vocab.decks.map(\.id) == ["a1-casa", "a2-viaje"])
        #expect(vocab.decks[0].words.map(\.id) == ["casa", "estudiante", "comer"].sorted { a, b in
            vocab.word(a)!.rank < vocab.word(b)!.rank })
        #expect(Word.itemID("casa") == "word:casa" && ItemKind.parse("word:casa") == .word)
        #expect(vocab.word("casa")?.display == "la casa")
    }

    @Test("Mode: production after two passing memory-updating reviews; Опять returns to recognition")
    func mode() {
        let id = "word:casa"
        #expect(VocabularyMode.mode(itemID: id, events: []) == .recognition)
        #expect(VocabularyMode.mode(itemID: id, events: [ev(id, .good, -3)]) == .recognition)
        #expect(VocabularyMode.mode(itemID: id, events: [ev(id, .good, -3), ev(id, .hard, -1)]) == .production)
        // Only the first grade per day counts (later same-day grades are not memory-updating).
        let sameDay = [ev(id, .good, -3), StudyEvent(cardID: id, date: day(-3).addingTimeInterval(60), grade: "good")]
        #expect(VocabularyMode.mode(itemID: id, events: sameDay, calendar: cal) == .recognition)
        #expect(VocabularyMode.mode(itemID: id, events: [ev(id, .good, -3), ev(id, .good, -2), ev(id, .again, -1)]) == .recognition)
    }

    @Test("Production check: article required, gender mistake reported, mf accepts el/la, accents")
    func production() {
        let casa = vocab.word("casa")!, est = vocab.word("estudiante")!, comer = vocab.word("comer")!
        #expect(VocabularyChecker.check(casa, typed: "La casa").verdict == .correct)
        let noArticle = VocabularyChecker.check(casa, typed: "casa")
        #expect(noArticle.verdict == .almost && noArticle.grade == .hard && noArticle.note == .missingArticle)
        let gender = VocabularyChecker.check(casa, typed: "el casa")
        #expect(gender.verdict == .wrong && gender.grade == .again && gender.note == .genderMistake)
        #expect(VocabularyChecker.check(est, typed: "la estudiante").verdict == .correct)
        #expect(VocabularyChecker.check(est, typed: "el estudiante").verdict == .correct)
        #expect(VocabularyChecker.check(comer, typed: "comer").verdict == .correct)
        let acc = VocabularyChecker.check(Word(id: "café", es: "café", pos: "noun", article: "el", gender: "m", ru: "кофе",
                                               exampleEs: "", exampleRu: "", rank: 1), typed: "el cafe")
        #expect(acc.verdict == .almost && acc.grade == .hard)
        #expect(VocabularyChecker.check(comer, typed: "beber").verdict == .wrong)
    }

    @Test("Planner: off by default; enabled 5; combined budget; personal first; selected decks; deterministic")
    func planner() {
        var s = UserSettings()
        #expect(s.dailyNewWordCount == 0)
        #expect(VocabularyPlanner.plan(vocab, settings: s, personal: [], reviews: [], introducedToday: [:], today: today).isEmpty)
        s.dailyNewWordCount = 5
        s.selectedDeckIDs = ["a1-casa"]
        let p = VocabularyPlanner.plan(vocab, settings: s, personal: ["word:viaje"], reviews: [], introducedToday: [:], today: today)
        #expect(p == ["word:viaje", "word:casa", "word:comer", "word:estudiante"])
        #expect(VocabularyPlanner.plan(vocab, settings: s, personal: [], reviews: [], introducedToday: [.card: 8], today: today).count == 2)
        let due = ReviewState(cardID: "word:comer", interval: 2, repetitions: 1, dueDate: day(-1), status: .review)
        let withDue = VocabularyPlanner.plan(vocab, settings: s, personal: [], reviews: [due], introducedToday: [:], today: today)
        #expect(withDue.first == "word:comer" && withDue.filter { $0 == "word:comer" }.count == 1)
        #expect(withDue == VocabularyPlanner.plan(vocab, settings: s, personal: [], reviews: [due], introducedToday: [:], today: today))
    }

    @Test("Lookup: normalisation and matching against es and forms")
    func lookup() {
        #expect(vocab.lookup("Casas")?.id == "casa")
        #expect(vocab.lookup("¡comió!")?.id == "comer")
        #expect(vocab.lookup("la casa")?.id == "casa")
        #expect(vocab.lookup("xyz") == nil)
    }
}
