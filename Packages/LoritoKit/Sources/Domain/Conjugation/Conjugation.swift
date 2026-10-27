import Foundation

/// A drillable tense or mood, mapped to the grammar card that teaches it.
public struct ConjugationTense: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let es: String
    public let ru: String
    public let mood: String
    public let level: CEFRLevel
    public let card: String
    public let order: Int
}

/// A verb with its complete paradigms (six forms per tense; reflexive forms
/// include the pronoun).
public struct ConjugationVerb: Codable, Sendable, Hashable {
    public let infinitive: String
    public let rank: Int
    public let ru: String
    public let reflexive: Bool
    public let paradigms: [String: [String]]
    /// Rioplatense `vos` form per tense (regional-variants); empty in older bundles.
    public let vos: [String: String]

    public init(infinitive: String, rank: Int, ru: String, reflexive: Bool, paradigms: [String: [String]],
                vos: [String: String] = [:]) {
        self.infinitive = infinitive
        self.rank = rank
        self.ru = ru
        self.reflexive = reflexive
        self.paradigms = paradigms
        self.vos = vos
    }

    private enum CodingKeys: String, CodingKey { case infinitive, rank, ru, reflexive, paradigms, vos }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        infinitive = try c.decode(String.self, forKey: .infinitive)
        rank = try c.decode(Int.self, forKey: .rank)
        ru = try c.decode(String.self, forKey: .ru)
        reflexive = try c.decode(Bool.self, forKey: .reflexive)
        paradigms = try c.decode([String: [String]].self, forKey: .paradigms)
        vos = try c.decodeIfPresent([String: String].self, forKey: .vos) ?? [:]
    }
}

/// The `conjugation` section of the content bundle.
public struct ConjugationCatalog: Codable, Sendable, Hashable {
    public let tenses: [ConjugationTense]
    public let verbs: [ConjugationVerb]

    public func verb(_ infinitive: String) -> ConjugationVerb? { verbs.first { $0.infinitive == infinitive } }
    public func tense(_ id: String) -> ConjugationTense? { tenses.first { $0.id == id } }
}

/// One SRS item: a verb in a tense, id `conj:<infinitive>:<tense-id>`.
public struct ConjugationItem: Sendable, Hashable, Identifiable {
    public let verb: ConjugationVerb
    public let tense: ConjugationTense

    public init(verb: ConjugationVerb, tense: ConjugationTense) {
        self.verb = verb
        self.tense = tense
    }

    public var id: String { Self.id(verb: verb.infinitive, tense: tense.id) }
    public var forms: [String] { verb.paradigms[tense.id] ?? [] }

    /// The form asked for `person` (paradigm index); Rioplatense asks `vos` in
    /// place of `tú` (falling back to `tú` when the bundle has no vos form).
    public func form(person: Int, variant: SpanishVariant) -> String {
        if person == 1, variant == .rioplatense, let vos = verb.vos[tense.id] { return vos }
        return forms.indices.contains(person) ? forms[person] : ""
    }

    public static func id(verb: String, tense: String) -> String { "conj:\(verb):\(tense)" }

    /// `conj:hablar:presente` → ("hablar", "presente").
    public static func parse(_ id: String) -> (verb: String, tense: String)? {
        let parts = id.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3, parts[0] == "conj" else { return nil }
        return (parts[1], parts[2])
    }

    public init?(id: String, catalog: ConjugationCatalog) {
        guard let p = Self.parse(id), let v = catalog.verb(p.verb), let t = catalog.tense(p.tense) else { return nil }
        self.init(verb: v, tense: t)
    }
}

public enum ConjugationUnlock {
    /// Tenses whose card has a review state and whose level is included, in registry order.
    public static func unlockedTenses(_ catalog: ConjugationCatalog, cards: [Card], reviews: [ReviewState],
                                      settings: UserSettings) -> [ConjugationTense] {
        let included = Set(settings.targetLevel?.included ?? [])
        let studied = Set(reviews.map(\.cardID))
        let levelByCard = Dictionary(cards.map { ($0.id, $0.level) }, uniquingKeysWith: { a, _ in a })
        return catalog.tenses
            .filter { t in studied.contains(t.card) && (levelByCard[t.card].map(included.contains) ?? false) }
            .sorted { $0.order < $1.order }
    }
}

public struct ConjugationPlan: Sendable, Hashable {
    public let due: [String]
    public let new: [String]

    public init(due: [String], new: [String]) {
        self.due = due
        self.new = new
    }
    public var all: [String] { due + new }
}

public enum ConjugationPlanner {
    public static let maxDuePerDay = 20

    /// Due `conj:` items (≤ 20, most overdue first, then id) plus new items
    /// within the quota and the combined daily budget (cards are served first),
    /// by verb rank within the earliest unlocked tense.
    public static func plan(_ catalog: ConjugationCatalog, unlocked: [ConjugationTense], reviews: [ReviewState],
                            events: [StudyEvent], quota: Int, cardQuota: Int = 0, introducedToday: [ItemKind: Int],
                            today: Date, calendar: Calendar = .learningDay) -> ConjugationPlan {
        let due = reviews
            .filter { $0.kind == .conjugation && DueSelection.isDue($0, on: today, calendar: calendar) }
            .sorted { $0.dueDate != $1.dueDate ? $0.dueDate < $1.dueDate : $0.cardID < $1.cardID }
            .prefix(maxDuePerDay)
            .map(\.cardID)

        let budget = DailyBudget(quotas: [.card: max(0, cardQuota), .conjugation: max(0, quota)])
        let allowance = budget.allowances(introducedToday: introducedToday)[.conjugation] ?? 0
        guard allowance > 0 else { return ConjugationPlan(due: Array(due), new: []) }
        let known = Set(reviews.map(\.cardID))
        var new: [String] = []
        outer: for tense in unlocked {
            for verb in catalog.verbs.sorted(by: { $0.rank < $1.rank }) where verb.paradigms[tense.id] != nil {
                let id = ConjugationItem.id(verb: verb.infinitive, tense: tense.id)
                guard !known.contains(id) else { continue }
                new.append(id)
                if new.count == allowance { break outer }
            }
        }
        return ConjugationPlan(due: Array(due), new: new)
    }
}

/// Which two persons a review asks: a pure function of the item id and the
/// number of graded events for it, cycling through the person set.
public enum PersonRotation {
    /// Indices into the paradigm order yo, tú, él, nosotros, vosotros, ellos.
    public static let spain = [0, 1, 2, 3, 4, 5]
    public static let personsPerReview = 2
    public static let labels = ["yo", "tú", "él / ella / usted", "nosotros", "vosotros", "ellos / ustedes"]

    /// Spain: six persons; Latin America: no vosotros; Rioplatense: vos (index 1), no vosotros.
    public static func personSet(for variant: SpanishVariant) -> [Int] {
        variant == .spain ? spain : [0, 1, 2, 3, 5]
    }

    public static func label(_ person: Int, variant: SpanishVariant) -> String {
        if person == 1, variant == .rioplatense { return "vos" }
        return labels.indices.contains(person) ? labels[person] : ""
    }

    public static func persons(itemID: String, gradedCount: Int, personSet: [Int]) -> [Int] {
        guard !personSet.isEmpty else { return [] }
        let n = personSet.count
        let start = Int(DailyTrap.stableHash(itemID) % UInt64(n))
        return (0..<min(personsPerReview, n)).map { personSet[(start + gradedCount * personsPerReview + $0) % n] }
    }

    public static func gradedCount(itemID: String, events: [StudyEvent]) -> Int {
        events.filter { $0.cardID == itemID && $0.grade != nil }.count
    }
}

public struct ConjugationCheck: Sendable, Hashable {
    public enum Verdict: Sendable { case correct, almost, wrong }
    public let verdict: Verdict
    public let grade: Grade
    /// The expected answer (shown on «почти» and wrong answers).
    public let expected: String
}

/// Accent-aware checking: exact → Хорошо; equal without diacritics → «почти»,
/// Трудно; otherwise Опять. Reflexive answers need the pronoun.
public enum ConjugationChecker {
    public static func check(expected: String, typed: String, reflexive: Bool = false) -> ConjugationCheck {
        let e = normalize(expected), t = normalize(typed)
        if e == t { return ConjugationCheck(verdict: .correct, grade: .good, expected: expected) }
        if fold(e) == fold(t) { return ConjugationCheck(verdict: .almost, grade: .hard, expected: expected) }
        if reflexive, let space = e.firstIndex(of: " ") {
            let verbPart = String(e[e.index(after: space)...])
            var typedVerb = t
            if let ts = t.firstIndex(of: " "), ["me", "te", "se", "nos", "os"].contains(String(t[..<ts])) {
                typedVerb = String(t[t.index(after: ts)...])
            }
            if fold(typedVerb) == fold(verbPart) {
                return ConjugationCheck(verdict: .almost, grade: .hard, expected: expected)
            }
        }
        return ConjugationCheck(verdict: .wrong, grade: .again, expected: expected)
    }

    /// The worse of the answers' grades decides the review.
    public static func combined(_ grades: [Grade]) -> Grade {
        let rank: [Grade: Int] = [.again: 0, .hard: 1, .good: 2, .easy: 3]
        return grades.min { (rank[$0] ?? 0) < (rank[$1] ?? 0) } ?? .again
    }

    static func normalize(_ s: String) -> String {
        s.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "es"))
    }
}
