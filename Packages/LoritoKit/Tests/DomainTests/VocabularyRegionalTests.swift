import Testing
import Foundation
@testable import Domain

private let json = #"""
{"decks": [
  {"id": "a1-casa", "level": "A1", "title_ru": "Дом", "order": 1, "words": [
    {"id": "casa", "es": "casa", "pos": "noun", "article": "la", "gender": "f", "ru": "дом", "example_es": "Mi casa es pequeña.", "example_ru": "Мой дом маленький.", "rank": 120, "forms": ["casas"]},
    {"id": "ordenador", "es": "ordenador", "pos": "noun", "article": "el", "gender": "m", "ru": "компьютер", "example_es": "Trabajo con {es: el ordenador | am: la computadora | rio: la compu}.", "example_ru": "Я работаю за компьютером.", "rank": 3000, "forms": ["ordenadores"], "variants": {"am": "la computadora", "rio": "la compu"}},
    {"id": "bolso", "es": "bolso", "pos": "noun", "article": "el", "gender": "m", "ru": "сумка", "example_es": "Mi {es: bolso | am: cartera} es negro.", "example_ru": "Моя сумка чёрная.", "rank": 4000, "forms": ["bolsos"], "variants": {"am": "la cartera"}},
    {"id": "conducir", "es": "conducir", "pos": "verb", "ru": "водить машину", "example_es": "No sé {es: conducir | am: manejar}.", "example_ru": "Я не умею водить.", "rank": 2500, "variants": {"am": "manejar", "rio": "manejar"}}
  ]},
  {"id": "a2-viaje", "level": "A2", "title_ru": "Путешествия", "order": 1, "words": [
    {"id": "viaje", "es": "viaje", "pos": "noun", "article": "el", "gender": "m", "ru": "поездка", "example_es": "Buen viaje.", "example_ru": "Счастливого пути.", "rank": 700}
  ]},
  {"id": "b1-trabajo", "level": "B1", "title_ru": "Работа", "order": 1, "words": []},
  {"id": "b2-economia", "level": "B2", "title_ru": "Экономика", "order": 1, "words": []},
  {"id": "c1-academico", "level": "C1", "title_ru": "Академический", "order": 1, "words": []},
  {"id": "c2-literario", "level": "C2", "title_ru": "Литература", "order": 1, "words": []}
]}
"""#
private let vocab = try! JSONDecoder().decode(VocabularyCatalog.self, from: Data(json.utf8))

@Suite("Vocabulary: regional word forms")
struct VocabularyRegionalTests {
    let ordenador = vocab.word("ordenador")!
    let bolso = vocab.word("bolso")!
    let conducir = vocab.word("conducir")!
    let casa = vocab.word("casa")!

    @Test("Forms decode by code; a noun form carries its own article and gender; fallback to Spain")
    func resolve() {
        #expect(ordenador.variants == [.latinAmerica: "la computadora", .rioplatense: "la compu"])
        let am = ordenador.resolved(for: .latinAmerica)
        #expect(am.id == "ordenador" && am.es == "computadora" && am.article == "la" && am.gender == "f")
        #expect(am.display == "la computadora" && am.ru == "компьютер")
        #expect(ordenador.resolved(for: .spain).display == "el ordenador")
        #expect(bolso.resolved(for: .rioplatense).display == "el bolso")
        #expect(conducir.resolved(for: .rioplatense).es == "manejar")
        #expect(casa.resolved(for: .latinAmerica) == casa)
    }

    @Test("Example renders the learner's inline form, without emphasis markers")
    func example() {
        #expect(ordenador.resolved(for: .latinAmerica).exampleEs == "Trabajo con la computadora.")
        #expect(ordenador.resolved(for: .spain).exampleEs == "Trabajo con el ordenador.")
        #expect(bolso.resolved(for: .rioplatense).exampleEs == "Mi bolso es negro.")
    }

    @Test("Other forms are listed with their region, the learner's own form excluded")
    func others() {
        #expect(ordenador.otherForms(for: .latinAmerica) == [VariantForm(variant: .spain, text: "el ordenador"),
                                                             VariantForm(variant: .rioplatense, text: "la compu")])
        #expect(bolso.otherForms(for: .spain) == [VariantForm(variant: .latinAmerica, text: "la cartera")])
        #expect(casa.otherForms(for: .spain).isEmpty)
    }

    @Test("Production: the learner's form is expected; every form is accepted with its own article")
    func production() {
        let am = VocabularyChecker.check(ordenador, typed: "la computadora", variant: .latinAmerica)
        #expect(am.verdict == .correct && am.expected == "la computadora")
        #expect(VocabularyChecker.check(ordenador, typed: "la computadora", variant: .spain).verdict == .correct)
        #expect(VocabularyChecker.check(ordenador, typed: "el ordenador", variant: .latinAmerica).verdict == .correct)
        let gender = VocabularyChecker.check(bolso, typed: "el cartera", variant: .latinAmerica)
        #expect(gender.verdict == .wrong && gender.note == .genderMistake)
        #expect(VocabularyChecker.check(conducir, typed: "manejar", variant: .spain).verdict == .correct)
        #expect(VocabularyChecker.check(conducir, typed: "conducir", variant: .rioplatense).expected == "manejar")
        #expect(VocabularyChecker.check(casa, typed: "la casa", variant: .rioplatense).verdict == .correct)
    }

    @Test("Lookup matches a regional form to its bundled word")
    func lookup() {
        #expect(vocab.lookup("computadora")?.id == "ordenador")
        #expect(vocab.lookup("la cartera")?.id == "bolso")
        #expect(vocab.lookup("manejar")?.id == "conducir")
        // A Spain form wins over another word's regional form.
        let both = try! JSONDecoder().decode(VocabularyCatalog.self, from: Data(#"""
        {"decks": [{"id": "a1-ropa", "level": "A1", "title_ru": "Одежда", "order": 1, "words": [
          {"id": "bolso", "es": "bolso", "pos": "noun", "article": "el", "gender": "m", "ru": "сумка", "rank": 1, "variants": {"rio": "la cartera"}}]},
         {"id": "a2-compras", "level": "A2", "title_ru": "Покупки", "order": 1, "words": [
          {"id": "cartera", "es": "cartera", "pos": "noun", "article": "la", "gender": "f", "ru": "кошелёк", "rank": 2}]}]}
        """#.utf8))
        #expect(both.lookup("cartera")?.id == "cartera")
    }
}

@Suite("Vocabulary: default deck selection")
struct VocabularySelectionTests {
    func settings(_ level: CEFRLevel?, selected: [String] = []) -> UserSettings {
        var s = UserSettings()
        s.targetLevel = level
        s.selectedDeckIDs = selected
        return s
    }

    @Test("Empty selection = decks of the included levels up to B2")
    func defaults() {
        #expect(VocabularySelection.selected(vocab.decks, settings: settings(.a2)) == ["a1-casa", "a2-viaje"])
        #expect(VocabularySelection.selected(vocab.decks, settings: settings(.c2))
                == ["a1-casa", "a2-viaje", "b1-trabajo", "b2-economia"])
        #expect(VocabularySelection.selected(vocab.decks, settings: settings(nil))
                == ["a1-casa", "a2-viaje", "b1-trabajo", "b2-economia"])
        #expect(VocabularySelection.selected(vocab.decks, settings: settings(.c2, selected: ["c1-academico"])) == ["c1-academico"])
    }

    @Test("Toggling starts from the default; back to the default stores an empty selection")
    func toggle() {
        let on = VocabularySelection.toggled("c1-academico", decks: vocab.decks, settings: settings(.c2))
        #expect(on == ["a1-casa", "a2-viaje", "b1-trabajo", "b2-economia", "c1-academico"])
        let off = VocabularySelection.toggled("c1-academico", decks: vocab.decks, settings: settings(.c2, selected: on))
        #expect(off == [])
        #expect(VocabularySelection.toggled("a1-casa", decks: vocab.decks, settings: settings(.a2)) == ["a2-viaje"])
    }

    @Test("The planner feeds new words only from the default decks")
    func planner() {
        var s = settings(.a1)
        s.dailyNewWordCount = 20
        let plan = VocabularyPlanner.plan(vocab, settings: s, personal: [], reviews: [], introducedToday: [:],
                                          today: Date(timeIntervalSince1970: 1_800_000_000))
        #expect(!plan.isEmpty && !plan.contains("word:viaje"))
    }
}
