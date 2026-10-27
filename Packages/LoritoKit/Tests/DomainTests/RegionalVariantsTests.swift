import Testing
import Foundation
@testable import Domain

@Suite("Spanish variant values")
struct SpanishVariantValueTests {
    @Test("Rioplatense exists; codes es/am/rio map both ways; Russian titles")
    func codes() {
        #expect(SpanishVariant.allCases == [.spain, .latinAmerica, .rioplatense])
        #expect(SpanishVariant.allCases.map(\.code) == ["es", "am", "rio"])
        #expect(SpanishVariant(code: "rio") == .rioplatense && SpanishVariant(code: "am") == .latinAmerica)
        #expect(SpanishVariant(code: "mx") == nil)
        #expect(SpanishVariant.rioplatense.title == "Риоплатский")
        #expect(SpanishVariant.rioplatense.regionName == "Аргентина и Уругвай")
    }

    @Test("Unknown or missing stored value decodes as spain")
    func decode() {
        #expect(SpanishVariant.decode("rioplatense") == .rioplatense)
        #expect(SpanishVariant.decode("chileno") == .spain)
        #expect(SpanishVariant.decode(nil) == .spain)
    }

    @Test("Voice order: Rioplatense es-AR → es-MX → es-ES")
    func voices() {
        #expect(SpanishVariant.rioplatense.voiceLanguages == ["es-AR", "es-MX", "es-ES"])
        #expect(SpanishVariant.latinAmerica.voiceLanguages == ["es-MX", "es-ES"])
        #expect(SpanishVariant.spain.voiceLanguages == ["es-ES"])
        #expect(SpanishVariant.rioplatense.localeIdentifier == "es-AR")
        #expect(SpanishVariant.rioplatense.preferredVoiceLanguage(installed: ["es-MX", "es-ES"]) == "es-MX")
        #expect(SpanishVariant.rioplatense.preferredVoiceLanguage(installed: ["es-ES"]) == "es-ES")
        #expect(SpanishVariant.rioplatense.preferredVoiceLanguage(installed: ["es-AR", "es-MX"]) == "es-AR")
        #expect(SpanishVariant.spain.preferredVoiceLanguage(installed: ["en-US"]) == nil)
    }
}

@Suite("Variant markup in card bodies")
struct VariantCardBodyTests {
    let body = """
    Общее правило.

    :::variant es
    В Испании говорят *vosotros habláis*.
    :::

    :::variant am rio
    В Америке — *ustedes hablan*.
    :::

    Машина: {es: coche | am: carro | rio: auto}. Множество {1, 2}.
    """

    @Test("Learner's block in place; other blocks become labelled notes, in order")
    func blocks() {
        let rio = CardBodyParser.parse(body, variant: .rioplatense)
        #expect(rio == [
            .markdown("Общее правило."),
            .variantNote(title: "В Испании", "В Испании говорят *vosotros habláis*."),
            .markdown("В Америке — *ustedes hablan*.\n\nМашина: *auto*. Множество {1, 2}."),
        ])
        let es = CardBodyParser.parse(body, variant: .spain)
        #expect(es == [
            .markdown("Общее правило.\n\nВ Испании говорят *vosotros habláis*."),
            .variantNote(title: "В Латинской Америке", "В Америке — *ustedes hablan*."),
            .markdown("Машина: *coche*. Множество {1, 2}."),
        ])
        #expect(CardBodyParser.parse(body) == es)
    }

    @Test("Note titles name the places of the block's codes")
    func titles() {
        #expect(VariantMarkup.noteTitle([.rioplatense]) == "В Аргентине и Уругвае")
        #expect(VariantMarkup.noteTitle([.latinAmerica, .rioplatense]) == "В Латинской Америке")
        #expect(VariantMarkup.noteTitle([.spain, .latinAmerica]) == "В Испании и Латинской Америке")
    }

    @Test("Inline: learner's form, missing form falls back to es; alternatives list every form")
    func inline() {
        #expect(VariantMarkup.resolveInline("{es: coche | am: carro}", for: .rioplatense) == "*coche*")
        #expect(VariantMarkup.resolveInline("{am: carro | rio: auto}", for: .spain) == "*carro*")
        #expect(VariantMarkup.resolveInline("{1, 2} и {нечто}", for: .spain) == "{1, 2} и {нечто}")
        let alts = VariantMarkup.alternatives(in: body, for: .latinAmerica)
        #expect(alts["carro"] == [VariantForm(variant: .spain, text: "coche"),
                                  VariantForm(variant: .latinAmerica, text: "carro"),
                                  VariantForm(variant: .rioplatense, text: "auto")])
        #expect(alts.count == 1)
    }

    @Test("Mistakes inside a variant callout still parse; plain body unchanged")
    func plain() {
        #expect(CardBodyParser.parse("Текст {a, b}.", variant: .latinAmerica) == [.markdown("Текст {a, b}.")])
    }
}

@Suite("Exercises per variant")
struct VariantExerciseTests {
    func decode(_ json: String) throws -> Exercise {
        try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
    }

    let base = #""id":"A1-EX-90","level":"A1","themeID":"a1-1","card":"A1-01","prompt":"p","explanation":"e""#

    @Test("Override replaces answer data for its variant only")
    func override() throws {
        let ex = try decode(#"{\#(base),"type":"multiple-choice","options":["vosotros habláis","ustedes hablan"],"answer":"vosotros habláis","variants":{"am":{"answer":"ustedes hablan"}}}"#)
        #expect(ex.resolved(for: .spain)?.kind == .multipleChoice(options: ["vosotros habláis", "ustedes hablan"], answer: "vosotros habláis"))
        #expect(ex.resolved(for: .latinAmerica)?.kind == .multipleChoice(options: ["vosotros habláis", "ustedes hablan"], answer: "ustedes hablan"))
        #expect(ex.resolved(for: .rioplatense)?.kind == ex.kind)
        let fill = try decode(#"{\#(base),"type":"fill-in-the-blank","answer":"habláis","accept":[],"variants":{"rio":{"answer":"hablan","accept":["hablan ustedes"]}}}"#)
        #expect(fill.resolved(for: .rioplatense)?.kind == .fillInTheBlank(answer: "hablan", accept: ["hablan ustedes"]))
    }

    @Test("`only` excludes other variants; catalog resolution filters and overrides")
    func only() throws {
        let ex = try decode(#"{\#(base),"type":"free-response","answer":"vosotros","only":["es"]}"#)
        #expect(ex.resolved(for: .spain) != nil)
        #expect(ex.resolved(for: .rioplatense) == nil && ex.resolved(for: .latinAmerica) == nil)
        let catalog = ContentCatalog(themes: [], cards: [], exercises: [ex])
        #expect(catalog.resolved(for: .rioplatense).exercises.isEmpty)
        #expect(catalog.resolved(for: .spain).exercises.count == 1)
    }

    @Test("Variant fields survive an encode/decode round trip")
    func roundTrip() throws {
        let ex = try decode(#"{\#(base),"type":"free-response","answer":"a","only":["es","am"],"variants":{"am":{"answer":"b"}}}"#)
        let again = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(ex))
        #expect(again == ex)
    }
}

@Suite("Conjugation persons per variant")
struct VariantPersonTests {
    let verb = ConjugationVerb(infinitive: "hablar", rank: 1, ru: "говорить", reflexive: false,
                               paradigms: ["presente": ["hablo", "hablas", "habla", "hablamos", "habláis", "hablan"]],
                               vos: ["presente": "hablás"])
    let tense = ConjugationTense(id: "presente", es: "Presente", ru: "Настоящее", mood: "indicativo", level: .a1,
                                 card: "A1-19", order: 1)

    @Test("Person sets: Spain six; Latin America without vosotros; Rioplatense vos, no vosotros")
    func sets() {
        #expect(PersonRotation.personSet(for: .spain) == [0, 1, 2, 3, 4, 5])
        #expect(PersonRotation.personSet(for: .latinAmerica) == [0, 1, 2, 3, 5])
        #expect(PersonRotation.personSet(for: .rioplatense) == [0, 1, 2, 3, 5])
        #expect(PersonRotation.label(1, variant: .rioplatense) == "vos")
        #expect(PersonRotation.label(1, variant: .spain) == "tú")
        #expect(PersonRotation.label(4, variant: .spain) == "vosotros")
    }

    @Test("Rioplatense asks the compiled vos form; missing vos falls back to tú")
    func vos() {
        let item = ConjugationItem(verb: verb, tense: tense)
        #expect(item.form(person: 1, variant: .rioplatense) == "hablás")
        #expect(item.form(person: 1, variant: .latinAmerica) == "hablas")
        #expect(item.form(person: 5, variant: .rioplatense) == "hablan")
        let old = ConjugationVerb(infinitive: "x", rank: 2, ru: "x", reflexive: false, paradigms: verb.paradigms)
        #expect(ConjugationItem(verb: old, tense: tense).form(person: 1, variant: .rioplatense) == "hablas")
    }

    @Test("Bundle without vos decodes")
    func decode() throws {
        let json = #"{"infinitive":"ser","rank":1,"ru":"быть","reflexive":false,"paradigms":{"presente":["soy","eres","es","somos","sois","son"]}}"#
        let v = try JSONDecoder().decode(ConjugationVerb.self, from: Data(json.utf8))
        #expect(v.vos.isEmpty)
    }
}
