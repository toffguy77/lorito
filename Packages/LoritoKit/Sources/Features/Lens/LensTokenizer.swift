import Foundation
import NaturalLanguage
import Domain

/// Grammar Lens tokens from the system tokenizer: `NLTokenizer` gives sentence
/// and word boundaries only; lemmas come from the compiled lemma table, so the
/// result doesn't depend on the device's language models. Words are kept when
/// they consist of letters (as in the pipeline's reference tokenizer).
public enum LensTokenizer {
    public static func tokens(_ text: String, lemmas: [String: String]) -> [LensToken] {
        // NLTokenizer isn't thread-safe: one instance per call.
        let sentences = NLTokenizer(unit: .sentence)
        sentences.string = text
        let words = NLTokenizer(unit: .word)
        words.string = text
        var out: [LensToken] = []
        var index = 0
        sentences.enumerateTokens(in: text.startIndex..<text.endIndex) { sentenceRange, _ in
            var hasWords = false
            words.enumerateTokens(in: sentenceRange) { range, _ in
                let surface = String(text[range])
                guard surface.allSatisfy(\.isLetter) else { return true }
                out.append(LensToken(surface: surface, sentence: index, lemma: lemmas[surface.lowercased()], range: range))
                hasWords = true
                return true
            }
            if hasWords { index += 1 }
            return true
        }
        return out
    }
}
