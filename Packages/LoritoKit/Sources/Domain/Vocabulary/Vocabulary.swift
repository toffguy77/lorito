import Foundation

/// A vocabulary word (dataset CC BY-SA 4.0, ranks from FrequencyWords).
public struct Word: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let es: String
    public let pos: String
    public let article: String?
    public let gender: String?
    public let ru: String
    public let exampleEs: String
    public let exampleRu: String
    public let rank: Int
    public let forms: [String]

    public init(id: String, es: String, pos: String, article: String? = nil, gender: String? = nil, ru: String,
                exampleEs: String, exampleRu: String, rank: Int, forms: [String] = []) {
        self.id = id
        self.es = es
        self.pos = pos
        self.article = article
        self.gender = gender
        self.ru = ru
        self.exampleEs = exampleEs
        self.exampleRu = exampleRu
        self.rank = rank
        self.forms = forms
    }

    enum CodingKeys: String, CodingKey {
        case id, es, pos, article, gender, ru, rank, forms
        case exampleEs = "example_es", exampleRu = "example_ru"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        es = try c.decode(String.self, forKey: .es)
        pos = try c.decode(String.self, forKey: .pos)
        article = try c.decodeIfPresent(String.self, forKey: .article)
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        ru = try c.decode(String.self, forKey: .ru)
        exampleEs = try c.decodeIfPresent(String.self, forKey: .exampleEs) ?? ""
        exampleRu = try c.decodeIfPresent(String.self, forKey: .exampleRu) ?? ""
        rank = try c.decode(Int.self, forKey: .rank)
        forms = try c.decodeIfPresent([String].self, forKey: .forms) ?? []
    }

    public var isNoun: Bool { pos == "noun" }
    /// "la casa" for nouns, otherwise the word itself.
    public var display: String { isNoun ? "\(article ?? "") \(es)".trimmingCharacters(in: .whitespaces) : es }

    public static func itemID(_ id: String) -> String { "word:\(id)" }
}

public struct Deck: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let level: CEFRLevel
    public let titleRu: String
    public let order: Int
    /// Ascending frequency rank.
    public let words: [Word]

    enum CodingKeys: String, CodingKey { case id, level, order, words, titleRu = "title_ru" }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        level = try c.decode(CEFRLevel.self, forKey: .level)
        titleRu = try c.decode(String.self, forKey: .titleRu)
        order = try c.decode(Int.self, forKey: .order)
        words = (try c.decodeIfPresent([Word].self, forKey: .words) ?? []).sorted { $0.rank < $1.rank }
    }
}

/// The `vocabulary` section of the content bundle.
public struct VocabularyCatalog: Codable, Sendable, Hashable {
    /// Level, then order.
    public let decks: [Deck]

    enum CodingKeys: String, CodingKey { case decks }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        decks = try c.decode([Deck].self, forKey: .decks).sorted { ($0.level, $0.order) < ($1.level, $1.order) }
    }

    public func word(_ id: String) -> Word? {
        for d in decks { if let w = d.words.first(where: { $0.id == id }) { return w } }
        return nil
    }

    /// Lookup of a tapped/typed Spanish word: case, punctuation and a leading
    /// article are ignored; matches `es` or any of `forms`.
    public func lookup(_ raw: String) -> Word? {
        let n = Self.normalize(raw)
        guard !n.isEmpty else { return nil }
        for d in decks {
            if let w = d.words.first(where: { Self.normalize($0.es) == n || $0.forms.contains { Self.normalize($0) == n } }) {
                return w
            }
        }
        return nil
    }

    static func normalize(_ s: String) -> String {
        var t = ExerciseChecker.dictationNormal(s)
        for article in ["el ", "la ", "los ", "las ", "un ", "una "] where t.hasPrefix(article) {
            t.removeFirst(article.count)
            break
        }
        return t
    }
}

public enum VocabularyMode: Sendable, Equatable {
    case recognition, production

    /// Production once the last two memory-updating (first-of-day) reviews passed.
    public static func mode(itemID: String, events: [StudyEvent], calendar: Calendar = .learningDay) -> VocabularyMode {
        var firstOfDay: [String: Grade] = [:]
        var days: [Date] = []
        for e in events.sorted(by: { $0.date < $1.date }) where e.cardID == itemID {
            guard let g = e.grade.flatMap(Grade.init(rawValue:)) else { continue }
            let d = calendar.startOfDay(for: e.date)
            let key = String(d.timeIntervalSince1970)
            if firstOfDay[key] == nil { firstOfDay[key] = g; days.append(d) }
        }
        let last = days.suffix(2).compactMap { firstOfDay[String($0.timeIntervalSince1970)] }
        return last.count == 2 && last.allSatisfy { $0 != .again } ? .production : .recognition
    }
}

public struct VocabularyCheck: Sendable, Equatable {
    public enum Verdict: Sendable { case correct, almost, wrong }
    public enum Note: Sendable { case missingArticle, genderMistake, accents }
    public let verdict: Verdict
    public let grade: Grade
    public let note: Note?
    public let expected: String
}

/// Production answers: nouns need their article; a wrong article is a gender
/// mistake; `mf` nouns accept el or la; accents follow the conjugation rule.
public enum VocabularyChecker {
    public static func check(_ word: Word, typed raw: String) -> VocabularyCheck {
        let typed = raw.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let expected = word.display
        guard word.isNoun else {
            let c = ConjugationChecker.check(expected: word.es, typed: typed)
            return VocabularyCheck(verdict: c.verdict == .correct ? .correct : c.verdict == .almost ? .almost : .wrong,
                                   grade: c.grade, note: c.verdict == .almost ? .accents : nil, expected: expected)
        }
        var article: String?
        var rest = typed
        for a in ["el", "la", "los", "las"] where typed.hasPrefix(a + " ") {
            article = a
            rest = String(typed.dropFirst(a.count + 1))
        }
        let exact = rest == word.es.lowercased()
        let folded = ConjugationChecker.fold(rest) == ConjugationChecker.fold(word.es.lowercased())
        guard exact || folded else {
            return VocabularyCheck(verdict: .wrong, grade: .again, note: nil, expected: expected)
        }
        guard let article else {
            return VocabularyCheck(verdict: .almost, grade: .hard, note: .missingArticle, expected: expected)
        }
        let articleOK = word.gender == "mf" ? true : article == word.article
        if !articleOK { return VocabularyCheck(verdict: .wrong, grade: .again, note: .genderMistake, expected: expected) }
        return exact ? VocabularyCheck(verdict: .correct, grade: .good, note: nil, expected: expected)
                     : VocabularyCheck(verdict: .almost, grade: .hard, note: .accents, expected: expected)
    }
}

/// Due words of selected decks and the personal deck, then new words up to the
/// quota inside the combined budget — personal first, then decks in level,
/// order and rank. Pure.
public enum VocabularyPlanner {
    public static let maxDuePerDay = 30

    public static func plan(_ catalog: VocabularyCatalog, settings: UserSettings, personal: [String],
                            reviews: [ReviewState], introducedToday: [ItemKind: Int], today: Date,
                            calendar: Calendar = .learningDay) -> [String] {
        let selected = settings.selectedDeckIDs.isEmpty ? Set(catalog.decks.map(\.id)) : Set(settings.selectedDeckIDs)
        let deckItems = catalog.decks.filter { selected.contains($0.id) }.flatMap { $0.words.map { Word.itemID($0.id) } }
        let pool = Set(deckItems + personal)
        let due = reviews.filter { pool.contains($0.cardID) && DueSelection.isDue($0, on: today, calendar: calendar) }
            .sorted { $0.dueDate != $1.dueDate ? $0.dueDate < $1.dueDate : $0.cardID < $1.cardID }
            .prefix(maxDuePerDay).map(\.cardID)
        let allowance = DailyBudget.standard(settings: settings).allowances(introducedToday: introducedToday)[.word] ?? 0
        let known = Set(reviews.map(\.cardID))
        var new: [String] = []
        for id in personal + deckItems where !known.contains(id) && !new.contains(id) && new.count < allowance {
            new.append(id)
        }
        return Array(due) + new
    }
}

/// A word the user saved that isn't in the bundled decks (synced).
public struct PersonalWord: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var es: String
    public var ru: String?
    public var sourceCardID: String?
    public var createdAt: Date

    public init(id: UUID = UUID(), es: String, ru: String? = nil, sourceCardID: String? = nil, createdAt: Date) {
        self.id = id
        self.es = es
        self.ru = ru
        self.sourceCardID = sourceCardID
        self.createdAt = createdAt
    }

    /// Personal-deck entry and review item: `p-<uuid>` / `word:p-<uuid>`.
    public var deckID: String { "p-\(id.uuidString.lowercased())" }
    public var itemID: String { Word.itemID(deckID) }

    public var asWord: Word {
        Word(id: deckID, es: es, pos: "phrase", ru: ru ?? "", exampleEs: "", exampleRu: "", rank: Int.max)
    }
}
