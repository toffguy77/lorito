import Foundation

public enum TrapConstants {
    /// Passes after the last failure that resolve a trap.
    public static let resolveAfterPasses = 2
    /// Traps per traps session.
    public static let sessionSize = 10
    /// Shown before «показать все».
    public static let listPreview = 20
}

/// An outcome of the traps session — deliberately outside SRS (synced).
public struct TrapPracticeEvent: Codable, Sendable, Hashable, Identifiable {
    public enum Outcome: String, Codable, Sendable {
        /// «Ещё путаю»
        case stillConfused
        /// «Ясно»
        case clear
    }

    public var id: UUID
    public var cardID: String
    public var date: Date
    public var outcome: Outcome

    public init(id: UUID = UUID(), cardID: String, date: Date, outcome: Outcome) {
        self.id = id
        self.cardID = cardID
        self.date = date
        self.outcome = outcome
    }
}

public struct PersonalTrap: Sendable, Hashable, Identifiable {
    public let cardID: String
    public let failures: Int
    /// Learning day of the last failure.
    public let lastFailure: Date
    /// The card's first «Частые ошибки» item (Markdown).
    public let firstMistake: String
    public var id: String { cardID }
}

/// The user's own traps, derived from the study log: a first-of-day Опять on
/// a `.card` with a «Частые ошибки» section is a failure; a first-of-day
/// Хорошо/Легко or «Ясно» is a pass; Трудно is neutral. Two passes after the
/// last failure resolve a trap, a new failure reopens it. Out-of-scope traps
/// are hidden, not deleted.
public enum PersonalTraps {
    public static func list(events: [StudyEvent], practice: [TrapPracticeEvent], catalog: ContentCatalog,
                            settings: UserSettings, today: Date, calendar: Calendar = .learningDay) -> [PersonalTrap] {
        // Only the first graded event per card and learning day counts.
        var firstOfDay: [String: (date: Date, grade: Grade)] = [:]
        for e in events.sorted(by: { $0.date < $1.date }) where e.isCard {
            guard let raw = e.grade, let grade = Grade(rawValue: raw) else { continue }
            let key = e.cardID + "|" + DailyTrap.dayKey(e.date, calendar: calendar)
            if firstOfDay[key] == nil { firstOfDay[key] = (e.date, grade) }
        }
        enum Signal { case fail, pass }
        var signals: [String: [(day: Date, signal: Signal)]] = [:]
        for (key, value) in firstOfDay {
            let cardID = String(key.split(separator: "|")[0])
            switch value.grade {
            case .again: signals[cardID, default: []].append((calendar.startOfDay(for: value.date), .fail))
            case .good, .easy: signals[cardID, default: []].append((calendar.startOfDay(for: value.date), .pass))
            case .hard: break
            }
        }
        // «Ясно» passes: one per card and learning day.
        var clearDays: Set<String> = []
        for p in practice where p.outcome == .clear {
            let key = p.cardID + "|" + DailyTrap.dayKey(p.date, calendar: calendar)
            if clearDays.insert(key).inserted {
                signals[p.cardID, default: []].append((calendar.startOfDay(for: p.date), .pass))
            }
        }

        let included = Set(settings.targetLevel?.included ?? [])
        let themes = Set(settings.selectedThemeIDs)
        var out: [(trap: PersonalTrap, order: Int)] = []
        for (cardID, list) in signals {
            guard let card = catalog.card(id: cardID), included.contains(card.level),
                  themes.isEmpty || themes.contains(card.themeID),
                  let mistake = CardBodyParser.firstMistake(in: card.body) else { continue }
            // By day; on the same day a failure comes first («Ясно» after an Опять that day).
            let sorted = list.sorted { a, b in
                if a.day != b.day { return a.day < b.day }
                return a.signal == .fail && b.signal == .pass
            }
            var failures = 0, passesSince = 0
            var lastFailure: Date?
            for s in sorted {
                switch s.signal {
                case .fail:
                    failures += 1
                    passesSince = 0
                    lastFailure = s.day
                case .pass:
                    passesSince += 1
                }
            }
            guard let lastFailure, passesSince < TrapConstants.resolveAfterPasses else { continue }
            out.append((PersonalTrap(cardID: cardID, failures: failures, lastFailure: lastFailure, firstMistake: mistake),
                        card.order))
        }
        return out.sorted { a, b in
            if a.trap.lastFailure != b.trap.lastFailure { return a.trap.lastFailure > b.trap.lastFailure }
            if a.trap.failures != b.trap.failures { return a.trap.failures > b.trap.failures }
            if a.order != b.order { return a.order < b.order }
            return a.trap.cardID < b.trap.cardID
        }.map(\.trap)
    }
}
