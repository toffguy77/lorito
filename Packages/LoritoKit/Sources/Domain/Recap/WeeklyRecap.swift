import Foundation

extension Calendar {
    /// The learning-day calendar with Monday–Sunday weeks.
    public var mondayWeeks: Calendar {
        var c = self
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
}

/// Facts about the most recently completed Monday–Sunday week.
public struct WeeklyRecap: Sendable, Hashable {
    public let weekStart: Date
    /// ISO week id ("2026-W43"), stored as `lastRecapWeek` once shown.
    public let weekID: String
    public let daysStudied: Int
    /// `.card` items whose first graded event falls in the week.
    public let newRules: Int
    /// Current long-term `.card` count across included levels (no weekly delta is kept).
    public let longTerm: Int
    public let topTrapCardID: String?

    public var isEmpty: Bool { daysStudied == 0 }

    public init(weekStart: Date, weekID: String, daysStudied: Int, newRules: Int, longTerm: Int, topTrapCardID: String?) {
        self.weekStart = weekStart
        self.weekID = weekID
        self.daysStudied = daysStudied
        self.newRules = newRules
        self.longTerm = longTerm
        self.topTrapCardID = topTrapCardID
    }

    public static func make(events: [StudyEvent], reviews: [ReviewState], practice: [TrapPracticeEvent],
                            catalog: ContentCatalog, settings: UserSettings, today: Date,
                            calendar: Calendar = .learningDay) -> WeeklyRecap {
        let cal = calendar.mondayWeeks
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? cal.startOfDay(for: today)
        let start = cal.date(byAdding: .day, value: -7, to: thisWeek) ?? thisWeek
        let inWeek: (Date) -> Bool = { $0 >= start && $0 < thisWeek }
        let graded = events.filter { $0.grade != nil }

        let days = Set(graded.filter { inWeek($0.date) }.map { cal.startOfDay(for: $0.date) }).count
        var firstSeen: [String: Date] = [:]
        for e in graded where e.isCard { firstSeen[e.cardID] = min(firstSeen[e.cardID] ?? e.date, e.date) }
        let newRules = firstSeen.values.filter(inWeek).count

        let levels = settings.targetLevel?.included ?? []
        let longTerm = StatsCalculator.longTermMemory(reviews: reviews, catalog: catalog, levels: levels)
            .reduce(0) { $0 + $1.longTerm }

        // First-of-day Опять per card in the week.
        var firstOfDay: [String: Grade] = [:]
        for e in graded.sorted(by: { $0.date < $1.date }) where e.isCard && inWeek(e.date) {
            let key = e.cardID + "|" + String(Int(cal.startOfDay(for: e.date).timeIntervalSince1970))
            if firstOfDay[key] == nil, let g = e.grade.flatMap(Grade.init(rawValue:)) { firstOfDay[key] = g }
        }
        var againCount: [String: Int] = [:]
        for (key, g) in firstOfDay where g == .again { againCount[String(key.split(separator: "|")[0]), default: 0] += 1 }
        let traps = Set(PersonalTraps.list(events: events, practice: practice, catalog: catalog, settings: settings,
                                           today: today, calendar: calendar).map(\.cardID))
        func top(_ ids: [String]) -> String? {
            ids.max { a, b in
                let (ca, cb) = (againCount[a] ?? 0, againCount[b] ?? 0)
                return ca != cb ? ca < cb : a > b
            }
        }
        let trapTop = top(againCount.keys.filter(traps.contains))
        let topTrap = trapTop ?? top(Array(againCount.keys))

        let iso = Calendar(identifier: .iso8601)
        var isoCal = iso
        isoCal.timeZone = cal.timeZone
        let c = isoCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start)
        let weekID = String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
        return WeeklyRecap(weekStart: start, weekID: weekID, daysStudied: days, newRules: newRules,
                           longTerm: longTerm, topTrapCardID: topTrap)
    }
}

public enum LevelMilestones {
    /// Included levels whose non-suspended `.card` items are all long-term and
    /// which haven't been celebrated yet.
    public static func newlyClosed(cards: [Card], reviews: [ReviewState], settings: UserSettings,
                                   celebrated: Set<CEFRLevel>) -> [CEFRLevel] {
        let byID = Dictionary(reviews.filter { $0.kind == .card }.map { ($0.cardID, $0) }, uniquingKeysWith: { a, _ in a })
        return (settings.targetLevel?.included ?? []).filter { level in
            guard !celebrated.contains(level) else { return false }
            let scope = cards.filter { $0.level == level && byID[$0.id]?.status != .suspended }
            return !scope.isEmpty && scope.allSatisfy { card in
                guard let r = byID[card.id] else { return false }
                return r.status == .review && r.interval >= StatsConstants.longTermIntervalDays
            }
        }
    }
}

/// Celebrated levels stored as one scalar of sorted codes ("A1,A2"); merging is
/// a union, so concurrent devices converge.
public enum CelebratedLevels {
    public static func encode(_ levels: Set<CEFRLevel>) -> String {
        levels.sorted().map(\.rawValue).joined(separator: ",")
    }

    public static func decode(_ raw: String?) -> Set<CEFRLevel> {
        Set((raw ?? "").split(separator: ",").compactMap { CEFRLevel(rawValue: String($0)) })
    }

    public static func merge(_ a: String?, _ b: String?) -> String {
        encode(decode(a).union(decode(b)))
    }
}
