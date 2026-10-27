import Foundation

// Study buddy: two learners share daily aggregates through a CloudKit share.
// Only these values cross devices — never cards, answers or the study log.

/// `yyyy-MM-dd` of the writer's local learning day.
public enum BuddyDayKey {
    public static func key(_ date: Date, calendar: Calendar = .learningDay) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Keys of the `count` learning days ending `today`, oldest first.
    public static func lastDays(_ count: Int, today: Date, calendar: Calendar = .learningDay) -> [String] {
        let start = calendar.startOfDay(for: today)
        return (0..<count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: start) }.map { key($0, calendar: calendar) }
    }
}

/// One learner's day (record `BuddyDay`, name `<owner>:<day>`).
public struct BuddyDay: Codable, Sendable, Hashable {
    /// The writer's CloudKit user record name.
    public let owner: String
    public let day: String
    public let studied: Bool
    public let gradedCount: Int
    public let currentStreak: Int
    public let displayName: String

    public init(owner: String, day: String, studied: Bool, gradedCount: Int, currentStreak: Int, displayName: String) {
        self.owner = owner
        self.day = day
        self.studied = studied
        self.gradedCount = gradedCount
        self.currentStreak = currentStreak
        self.displayName = displayName
    }

    public var recordName: String { "\(owner):\(day)" }
}

/// «Напомнить» (record `BuddyNudge`, name `<from>:<day>` — one per sender per day).
public struct BuddyNudge: Codable, Sendable, Hashable {
    public let from: String
    public let day: String

    public init(from: String, day: String) {
        self.from = from
        self.day = day
    }

    public var recordName: String { "\(from):\(day)" }
}

/// Consecutive learning days on which both studied, ending today — or yesterday
/// while today isn't done by both. A freeze isn't study, so it breaks the run.
public enum SharedStreakCalculator {
    public static func streak(mine: [BuddyDay], theirs: [BuddyDay], today: Date,
                              calendar: Calendar = .learningDay) -> Int {
        let a = Set(mine.filter(\.studied).map(\.day)), b = Set(theirs.filter(\.studied).map(\.day))
        let both = a.intersection(b)
        var day = calendar.startOfDay(for: today)
        if !both.contains(BuddyDayKey.key(day, calendar: calendar)) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var count = 0
        while both.contains(BuddyDayKey.key(day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}

/// At most one nudge per sender per day, and none once the partner studied that day.
public enum NudgeRule {
    public static func canNudge(from sender: String, sent: [BuddyNudge], partnerDays: [BuddyDay], today: Date,
                                calendar: Calendar = .learningDay) -> Bool {
        let key = BuddyDayKey.key(today, calendar: calendar)
        if sent.contains(where: { $0.from == sender && $0.day == key }) { return false }
        return !partnerDays.contains { $0.day == key && $0.studied }
    }
}

/// What a learner publishes: the last 14 learning days from their own log.
public enum BuddyAggregate {
    public static let publishedDays = 14

    public static func days(events: [StudyEvent], today: Date, owner: String, displayName: String,
                            calendar: Calendar = .learningDay) -> [BuddyDay] {
        let graded = events.filter { $0.grade != nil }
        let start = calendar.startOfDay(for: today)
        return (0..<publishedDays).reversed().compactMap { offset -> BuddyDay? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start),
                  let end = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            let count = graded.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            let upToDay = events.filter { $0.date < end }
            let streak = StatsCalculator.compute(events: upToDay, today: day, calendar: calendar).currentStreak
            return BuddyDay(owner: owner, day: BuddyDayKey.key(day, calendar: calendar), studied: count > 0,
                            gradedCount: count, currentStreak: streak, displayName: displayName)
        }
    }

    /// The partner's last seven days (oldest first); missing days count as not studied.
    public static func lastSeven(_ days: [BuddyDay], today: Date, calendar: Calendar = .learningDay) -> [BuddyDay] {
        let byKey = Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { a, _ in a })
        return BuddyDayKey.lastDays(7, today: today, calendar: calendar).map {
            byKey[$0] ?? BuddyDay(owner: days.first?.owner ?? "", day: $0, studied: false, gradedCount: 0, currentStreak: 0,
                                  displayName: days.first?.displayName ?? "")
        }
    }
}
