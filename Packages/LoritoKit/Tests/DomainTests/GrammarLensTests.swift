import Testing
import Foundation
@testable import Domain

/// Fixtures mirror `LensMatcherTests` in tools/test_pipeline.py.
private let table = ["espero": "esperar", "quiero": "querer", "vengas": "venir", "llames": "llamar",
                     "vienes": "venir", "creo": "creer"]
private let sets = ["presente-subjuntivo": ["vengas", "llames", "venga"]]

private func rule(_ id: String = "subj-esperar-que", pattern: [LensStep]? = nil, requires: [LensContext] = []) -> LensRule {
    LensRule(id: id, titleRu: "Subjuntivo", cards: ["A1-01"],
             pattern: pattern ?? [LensStep(lemma: ["esperar", "querer"]), LensStep(surface: ["que"]),
                                  LensStep(set: "presente-subjuntivo", gap: 3)],
             requires: requires)
}
private func toks(_ text: String) -> [LensToken] { LensReferenceTokenizer.tokens(text, lemmas: table) }

@Suite("Grammar Lens matcher")
struct GrammarLensMatcherTests {
    @Test("Reference tokenizer: letter runs, sentence breaks at . ! ? …, ¿ ¡ ignored")
    func tokenizer() {
        let t = LensReferenceTokenizer.tokenize("¿Vienes? Sí, voy.  Espero que vengas")
        #expect(t.map(\.lower) == ["vienes", "sí", "voy", "espero", "que", "vengas"])
        #expect(t.map(\.sentence) == [0, 1, 1, 2, 2, 2])
        #expect(t[0].surface == "Vienes")
        #expect(toks("Espero")[0].lemma == "esperar")
    }

    @Test("Pattern with a gap; steps stay in one sentence; no match without the predicates")
    func gaps() {
        let m = LensMatcher.match(toks("Espero que mañana vengas."), rules: [rule()], sets: sets)
        #expect(m == [LensMatch(rule: "subj-esperar-que", start: 0, end: 3)])
        #expect(LensMatcher.match(toks("Espero que sí. Vengas."), rules: [rule()], sets: sets).isEmpty)
        #expect(LensMatcher.match(toks("Espero el autobús."), rules: [rule()], sets: sets).isEmpty)
    }

    @Test("Context requirements")
    func context() {
        let r = rule("x", pattern: [LensStep(surface: ["que"])],
                     requires: [LensContext(kind: .notBefore, step: LensStep(lemma: ["creer"]), within: 2)])
        #expect(LensMatcher.match(toks("Espero que"), rules: [r], sets: sets).count == 1)
        #expect(LensMatcher.match(toks("Creo que"), rules: [r], sets: sets).isEmpty)
    }

    @Test("Overlaps keep the longest, then the more specific, then the lower id; order-independent")
    func overlaps() {
        let short = rule("a-short", pattern: [LensStep(surface: ["que"]), LensStep(set: "presente-subjuntivo")])
        let long = rule("b-long")
        #expect(LensMatcher.match(toks("Espero que vengas"), rules: [short, long], sets: sets).map(\.rule) == ["b-long"])
        let z = rule("z", pattern: [LensStep(surface: ["que"])])
        let y = rule("y", pattern: [LensStep(surface: ["que"])],
                     requires: [LensContext(kind: .before, step: LensStep(lemma: ["esperar"]), within: 1)])
        #expect(LensMatcher.match(toks("Espero que"), rules: [z, y], sets: sets).map(\.rule) == ["y"])
        #expect(LensMatcher.match(toks("Espero que vengas"), rules: [short, long], sets: sets)
                == LensMatcher.match(toks("Espero que vengas"), rules: [long, short], sets: sets))
    }

    @Test("lens.json decodes: rules with steps, context and examples; lemmas; sets")
    func decode() throws {
        let json = #"""
        {"rules": [{"id": "r", "title_ru": "Т", "cards": ["B1-02"],
                    "pattern": [{"lemma": ["querer"]}, {"surface": ["que"]}, {"set": "s", "gap": 3}],
                    "requires": [{"not_before": {"surface": ["no"]}, "within": 2}],
                    "examples": {"positive": ["a"], "negative": ["b"]}}],
         "lemmas": {"quiero": "querer"}, "sets": {"s": ["vengas"]}, "crosscheck": []}
        """#
        let c = try JSONDecoder().decode(LensCatalog.self, from: Data(json.utf8))
        #expect(c.rules[0].pattern[2] == LensStep(set: "s", gap: 3))
        #expect(c.rules[0].requires == [LensContext(kind: .notBefore, step: LensStep(surface: ["no"]), within: 2)])
        #expect(c.rules[0].titleRu == "Т" && c.lemmas["quiero"] == "querer" && c.sets["s"] == ["vengas"])
    }
}
