import Foundation

/// The small, versioned snapshot the app publishes for its widgets. Widgets
/// read only this — never the user-data store.
public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public static let currentVersion = 1
    public static let maxQuestions = 3

    public struct WordOfDay: Codable, Sendable, Equatable {
        public let spanish: String
        /// Short Russian note (the source card's title).
        public let note: String
        public let cardID: String

        public init(spanish: String, note: String, cardID: String) {
            self.spanish = spanish
            self.note = note
            self.cardID = cardID
        }
    }

    /// A multiple-choice practice question for the interactive widget.
    public struct Question: Codable, Sendable, Equatable, Identifiable {
        public let id: String
        /// Markdown prompt.
        public let prompt: String
        public let options: [String]
        public let answer: String
        public let cardID: String

        public init(id: String, prompt: String, options: [String], answer: String, cardID: String) {
            self.id = id
            self.prompt = prompt
            self.options = options
            self.answer = answer
            self.cardID = cardID
        }
    }

    public let version: Int
    public let generatedAt: Date
    /// Start of the learning day the snapshot describes.
    public let day: Date
    public let currentStreak: Int
    public let studiedToday: Bool
    public let dueToday: Int
    public let newToday: Int
    public let remainingToday: Int
    public let wordOfDay: WordOfDay?
    public let questions: [Question]

    public init(version: Int = WidgetSnapshot.currentVersion, generatedAt: Date, day: Date, currentStreak: Int,
                studiedToday: Bool, dueToday: Int, newToday: Int, remainingToday: Int,
                wordOfDay: WordOfDay?, questions: [Question]) {
        self.version = version
        self.generatedAt = generatedAt
        self.day = day
        self.currentStreak = currentStreak
        self.studiedToday = studiedToday
        self.dueToday = dueToday
        self.newToday = newToday
        self.remainingToday = remainingToday
        self.wordOfDay = wordOfDay
        self.questions = questions
    }

    /// Pure builder. `dueToday`/`newToday` are the cards still to study today;
    /// `exercises` are those in the user's scope; `trap` is the day's trap.
    public static func make(
        stats: StudyStats,
        dueToday: Int,
        newToday: Int,
        trap: TrapCandidate?,
        trapNote: String?,
        exercises: [Exercise],
        today: Date,
        calendar: Calendar = .learningDay
    ) -> WidgetSnapshot {
        let word = trap.flatMap { trap in
            spanishPhrase(inMarkdown: trap.text).map {
                WordOfDay(spanish: $0, note: trapNote ?? "", cardID: trap.cardID)
            }
        }
        return WidgetSnapshot(
            generatedAt: today,
            day: calendar.startOfDay(for: today),
            currentStreak: stats.currentStreak,
            studiedToday: stats.studiedToday > 0,
            dueToday: dueToday,
            newToday: newToday,
            remainingToday: dueToday + newToday,
            wordOfDay: word,
            questions: questions(from: exercises, day: today, calendar: calendar)
        )
    }

    /// Up to three multiple-choice questions, a stable window per day over the
    /// exercises sorted by id.
    static func questions(from exercises: [Exercise], day: Date, calendar: Calendar = .learningDay) -> [Question] {
        let pool: [Question] = exercises.sorted { $0.id < $1.id }.compactMap { ex in
            guard case let .multipleChoice(options, answer) = ex.kind else { return nil }
            return Question(id: ex.id, prompt: ex.prompt, options: options, answer: answer, cardID: ex.cardID)
        }
        guard !pool.isEmpty else { return [] }
        let start = Int(DailyTrap.stableHash(DailyTrap.dayKey(day, calendar: calendar)) % UInt64(pool.count))
        return (0..<min(maxQuestions, pool.count)).map { pool[(start + $0) % pool.count] }
    }

    /// The first emphasised (`*…*`) phrase — the content's marker for Spanish.
    public static func spanishPhrase(inMarkdown markdown: String) -> String? {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let parsed = try? AttributedString(markdown: markdown, options: options) else { return nil }
        var phrase = ""
        var started = false
        for run in parsed.runs {
            let emphasized = run.inlinePresentationIntent?.contains(.emphasized) == true
            if emphasized {
                phrase += String(parsed[run.range].characters)
                started = true
            } else if started {
                break
            }
        }
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
