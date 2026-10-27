import Foundation

// Grammar Lens: authored rules matched over tokens. Mirrors tools/lens.py (the
// pipeline's reference); `lens.json` carries a cross-check table of every rule
// example so the two can't drift. Pure — the app fills tokens from the system
// tokenizer (boundaries only) and lemmas from the compiled table.

/// One word of the analysed text.
public struct LensToken: Sendable, Hashable {
    public let surface: String
    public let lower: String
    public let sentence: Int
    public let lemma: String?
    /// Position in the analysed text (for highlighting); nil in fixtures.
    public let range: Range<String.Index>?

    public init(surface: String, sentence: Int, lemma: String? = nil, range: Range<String.Index>? = nil) {
        self.surface = surface
        self.lower = surface.lowercased()
        self.sentence = sentence
        self.lemma = lemma
        self.range = range
    }
}

/// A token predicate: surface and lemma tests only (all present keys must hold).
public struct LensStep: Codable, Sendable, Hashable {
    public var surface: [String]?
    public var lemma: [String]?
    public var set: String?
    /// Tokens allowed before this step (same sentence).
    public var gap: Int

    public init(surface: [String]? = nil, lemma: [String]? = nil, set: String? = nil, gap: Int = 0) {
        self.surface = surface
        self.lemma = lemma
        self.set = set
        self.gap = gap
    }

    private enum CodingKeys: String, CodingKey { case surface, lemma, set, gap }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        surface = try c.decodeIfPresent([String].self, forKey: .surface)
        lemma = try c.decodeIfPresent([String].self, forKey: .lemma)
        set = try c.decodeIfPresent(String.self, forKey: .set)
        gap = try c.decodeIfPresent(Int.self, forKey: .gap) ?? 0
    }

    var predicateCount: Int { [surface != nil, lemma != nil, set != nil].filter { $0 }.count }

    func holds(_ t: LensToken, sets: [String: Set<String>]) -> Bool {
        if let surface, !surface.contains(where: { $0.lowercased() == t.lower }) { return false }
        if let lemma, !(t.lemma.map(lemma.contains) ?? false) { return false }
        if let set, !(sets[set]?.contains(t.lower) ?? false) { return false }
        return true
    }
}

/// A context predicate around the matched span.
public struct LensContext: Codable, Sendable, Hashable {
    public enum Kind: String, Sendable, CaseIterable {
        case before, notBefore = "not_before", after, notAfter = "not_after"
    }
    public let kind: Kind
    public let step: LensStep
    public let within: Int

    public init(kind: Kind, step: LensStep, within: Int) {
        self.kind = kind
        self.step = step
        self.within = within
    }

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        guard let kind = Kind.allCases.first(where: { c.contains(Key(stringValue: $0.rawValue)) }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: c.codingPath, debugDescription: "no context kind"))
        }
        self.kind = kind
        step = try c.decode(LensStep.self, forKey: Key(stringValue: kind.rawValue))
        within = try c.decodeIfPresent(Int.self, forKey: Key(stringValue: "within")) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encode(step, forKey: Key(stringValue: kind.rawValue))
        try c.encode(within, forKey: Key(stringValue: "within"))
    }
}

public struct LensExamples: Codable, Sendable, Hashable {
    public let positive: [String]
    public let negative: [String]

    public init(positive: [String], negative: [String]) {
        self.positive = positive
        self.negative = negative
    }
}

public struct LensRule: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let titleRu: String
    public let cards: [String]
    public let pattern: [LensStep]
    public let requires: [LensContext]
    public let examples: LensExamples

    public init(id: String, titleRu: String, cards: [String], pattern: [LensStep], requires: [LensContext] = [],
                examples: LensExamples = LensExamples(positive: [], negative: [])) {
        self.id = id
        self.titleRu = titleRu
        self.cards = cards
        self.pattern = pattern
        self.requires = requires
        self.examples = examples
    }

    private enum CodingKeys: String, CodingKey { case id, titleRu = "title_ru", cards, pattern, requires, examples }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titleRu = try c.decode(String.self, forKey: .titleRu)
        cards = try c.decode([String].self, forKey: .cards)
        pattern = try c.decode([LensStep].self, forKey: .pattern)
        requires = try c.decodeIfPresent([LensContext].self, forKey: .requires) ?? []
        examples = try c.decodeIfPresent(LensExamples.self, forKey: .examples) ?? LensExamples(positive: [], negative: [])
    }

    /// Tie-break between equally long overlapping matches.
    var specificity: Int { pattern.reduce(0) { $0 + $1.predicateCount } + requires.count }
}

/// A highlighted span: token indices, inclusive.
public struct LensMatch: Sendable, Hashable {
    public let rule: String
    public let start: Int
    public let end: Int

    public init(rule: String, start: Int, end: Int) {
        self.rule = rule
        self.start = start
        self.end = end
    }
}

/// One rule example analysed by the pipeline with every rule.
public struct LensCrossCheck: Codable, Sendable, Hashable {
    public let text: String
    public let tokens: [String]
    public let sentences: [Int]
    /// `[rule, start, end]`.
    public let matches: [[LensCrossCheckValue]]
}

public enum LensCrossCheckValue: Codable, Sendable, Hashable {
    case string(String), int(Int)
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .int(i) } else { self = .string(try c.decode(String.self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .int(let i): try c.encode(i)
        }
    }
}

/// `lens.json`: rules, the lemma table (form → lemma) and surface sets.
public struct LensCatalog: Codable, Sendable {
    public let rules: [LensRule]
    public let lemmas: [String: String]
    public let sets: [String: [String]]
    public let crosscheck: [LensCrossCheck]

    public init(rules: [LensRule], lemmas: [String: String], sets: [String: [String]], crosscheck: [LensCrossCheck] = []) {
        self.rules = rules
        self.lemmas = lemmas
        self.sets = sets
        self.crosscheck = crosscheck
    }

    private enum CodingKeys: String, CodingKey { case rules, lemmas, sets, crosscheck }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rules = try c.decode([LensRule].self, forKey: .rules)
        lemmas = try c.decode([String: String].self, forKey: .lemmas)
        sets = try c.decode([String: [String]].self, forKey: .sets)
        crosscheck = try c.decodeIfPresent([LensCrossCheck].self, forKey: .crosscheck) ?? []
    }

    public func rule(_ id: String) -> LensRule? { rules.first { $0.id == id } }

    /// Rule titles, for the empty state («Lens узнаёт: …»).
    public var coveredTopics: [String] { rules.map(\.titleRu) }

    public func match(_ tokens: [LensToken]) -> [LensMatch] {
        LensMatcher.match(tokens, rules: rules, sets: sets)
    }
}

/// The pure matcher (same semantics as tools/lens.py `match`).
public enum LensMatcher {
    public static func match(_ tokens: [LensToken], rules: [LensRule], sets: [String: [String]]) -> [LensMatch] {
        let sets = sets.mapValues(Set.init)
        var candidates: [(length: Int, specificity: Int, rule: String, start: Int, end: Int)] = []
        for rule in rules {
            for i in tokens.indices {
                if let end = matchFrom(rule, tokens, i, sets), contextHolds(rule, tokens, i, end, sets) {
                    candidates.append((end - i, rule.specificity, rule.id, i, end))
                }
            }
        }
        candidates.sort {
            if $0.length != $1.length { return $0.length > $1.length }
            if $0.specificity != $1.specificity { return $0.specificity > $1.specificity }
            if $0.rule != $1.rule { return $0.rule < $1.rule }
            return $0.start < $1.start
        }
        var taken: [LensMatch] = []
        for c in candidates where taken.allSatisfy({ c.end < $0.start || c.start > $0.end }) {
            taken.append(LensMatch(rule: c.rule, start: c.start, end: c.end))
        }
        return taken.sorted { $0.start < $1.start }
    }

    /// End of the leftmost pattern match starting at `start` (backtracking over gaps).
    static func matchFrom(_ rule: LensRule, _ t: [LensToken], _ start: Int, _ sets: [String: Set<String>]) -> Int? {
        guard let first = rule.pattern.first, first.holds(t[start], sets: sets) else { return nil }
        func step(_ k: Int, _ prev: Int) -> Int? {
            if k == rule.pattern.count { return prev }
            let s = rule.pattern[k]
            var j = prev + 1
            while j < min(prev + 2 + s.gap, t.count) {
                if t[j].sentence != t[start].sentence { break }
                if s.holds(t[j], sets: sets), let end = step(k + 1, j) { return end }
                j += 1
            }
            return nil
        }
        return step(1, start)
    }

    static func contextHolds(_ rule: LensRule, _ t: [LensToken], _ start: Int, _ end: Int,
                             _ sets: [String: Set<String>]) -> Bool {
        let sentence = t[start].sentence
        for req in rule.requires {
            let window: Range<Int>
            switch req.kind {
            case .before, .notBefore: window = max(0, start - req.within)..<start
            case .after, .notAfter: window = (end + 1)..<min(t.count, end + 1 + req.within)
            }
            let found = window.contains { t[$0].sentence == sentence && req.step.holds(t[$0], sets: sets) }
            let negative = req.kind == .notBefore || req.kind == .notAfter
            if found == negative { return false }
        }
        return true
    }
}

/// The pipeline's tokenizer, in Swift: letter runs are words; `.` `!` `?` `…`
/// end a sentence. The app's system-tokenizer adapter is checked against it.
public enum LensReferenceTokenizer {
    public static func tokenize(_ text: String) -> [LensToken] {
        var out: [LensToken] = []
        var sentence = 0, hasWords = false
        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]
            if ch.isLetter {
                var j = text.index(after: i)
                while j < text.endIndex, text[j].isLetter { j = text.index(after: j) }
                out.append(LensToken(surface: String(text[i..<j]), sentence: sentence, range: i..<j))
                hasWords = true
                i = j
            } else {
                if ".!?…".contains(ch), hasWords { sentence += 1; hasWords = false }
                i = text.index(after: i)
            }
        }
        return out
    }

    public static func tokens(_ text: String, lemmas: [String: String]) -> [LensToken] {
        tokenize(text).map { LensToken(surface: $0.surface, sentence: $0.sentence, lemma: lemmas[$0.lower], range: $0.range) }
    }
}
