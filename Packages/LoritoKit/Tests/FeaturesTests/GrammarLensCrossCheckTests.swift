import Foundation
import Testing
import Domain
import Content
@testable import Features

@Suite("Grammar Lens cross-check with the pipeline")
struct GrammarLensCrossCheckTests {
    @Test("Bundled lens.json has ≥ 20 rules whose cards exist")
    func bundle() throws {
        let lens = try ContentLoader.loadLens()
        let cards = Set(try ContentLoader.loadCatalog().cards.map(\.id))
        #expect(lens.rules.count >= 20)
        #expect(lens.rules.allSatisfy { $0.cards.allSatisfy(cards.contains) })
        #expect(!lens.crosscheck.isEmpty)
    }

    @Test("Swift reference tokens and matches equal the pipeline's on every rule example")
    func crossCheck() throws {
        let lens = try ContentLoader.loadLens()
        for c in lens.crosscheck {
            let tokens = LensReferenceTokenizer.tokens(c.text, lemmas: lens.lemmas)
            #expect(tokens.map(\.lower) == c.tokens, "\(c.text)")
            #expect(tokens.map(\.sentence) == c.sentences, "\(c.text)")
            let expected = c.matches.map { m -> LensMatch in
                guard case .string(let r) = m[0], case .int(let s) = m[1], case .int(let e) = m[2] else {
                    return LensMatch(rule: "?", start: -1, end: -1)
                }
                return LensMatch(rule: r, start: s, end: e)
            }
            #expect(lens.match(tokens) == expected, "\(c.text)")
        }
    }
}

@Suite("Grammar Lens system tokenizer")
struct LensTokenizerTests {
    @Test("NLTokenizer tokens equal the pipeline's reference tokens on every rule example")
    func crossCheck() throws {
        let lens = try ContentLoader.loadLens()
        for c in lens.crosscheck {
            let tokens = LensTokenizer.tokens(c.text, lemmas: lens.lemmas)
            #expect(tokens.map(\.lower) == c.tokens, "\(c.text)")
            #expect(tokens.map(\.sentence) == c.sentences, "\(c.text)")
        }
    }

    @Test("Espero que vengas mañana → the subjunctive rule over «Espero que vengas»")
    func scenario() throws {
        let lens = try ContentLoader.loadLens()
        let text = "Espero que vengas mañana"
        let tokens = LensTokenizer.tokens(text, lemmas: lens.lemmas)
        let m = try #require(lens.match(tokens).first)
        #expect(m.rule == "subj-deseo")
        #expect(text[tokens[m.start].range!.lowerBound..<tokens[m.end].range!.upperBound] == "Espero que vengas")
        #expect(lens.rule(m.rule)?.cards == ["B1-02"])
    }
}
