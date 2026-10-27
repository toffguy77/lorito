import Foundation

/// Named constants for the progress insights.
public enum StatsConstants {
    /// A card is in long-term memory once its review interval reaches this.
    public static let longTermIntervalDays = 21
    /// Days covered by the progress heatmap (12 weeks).
    public static let heatmapDays = 84
}

/// Grade events on one calendar day.
public struct DailyActivity: Equatable, Sendable {
    /// Start of the day in the stats calendar.
    public let day: Date
    public let count: Int

    public init(day: Date, count: Int) {
        self.day = day
        self.count = count
    }
}

/// Long-term memory for one level: cards with interval ≥ 21 days of the
/// level's non-suspended cards.
public struct LevelMemory: Equatable, Sendable {
    public let level: CEFRLevel
    public let longTerm: Int
    public let total: Int

    public init(level: CEFRLevel, longTerm: Int, total: Int) {
        self.level = level
        self.longTerm = longTerm
        self.total = total
    }
}

public extension StatsCalculator {
    /// Grade events per day for the last `days` days ending `today`, oldest
    /// first, on the same day boundary as the streak.
    static func dailyActivity(
        events: [StudyEvent],
        days: Int,
        today: Date,
        calendar: Calendar = .utcDay
    ) -> [DailyActivity] {
        guard days > 0 else { return [] }
        let today0 = calendar.startOfDay(for: today)
        var perDay: [Date: Int] = [:]
        for event in events where event.grade != nil {
            perDay[calendar.startOfDay(for: event.date), default: 0] += 1
        }
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today0)!
            return DailyActivity(day: day, count: perDay[day] ?? 0)
        }
    }

    /// Intensity bucket (0–3) per count: 0 for no activity; otherwise relative
    /// to the non-zero counts' quartiles (nearest rank) — ≥ Q3 → 3, > Q1 → 2,
    /// else 1. A single value or all ties land in 3.
    static func buckets(for counts: [Int]) -> [Int] {
        let nonZero = counts.filter { $0 > 0 }.sorted()
        guard !nonZero.isEmpty else { return counts.map { _ in 0 } }
        func rank(_ p: Double) -> Int {
            nonZero[max(0, Int((p * Double(nonZero.count)).rounded(.up)) - 1)]
        }
        let q1 = rank(0.25), q3 = rank(0.75)
        return counts.map { c in
            if c <= 0 { return 0 }
            if c >= q3 { return 3 }
            return c > q1 ? 2 : 1
        }
    }

    /// Long-term memory per level, in the order of `levels`.
    static func longTermMemory(reviews: [ReviewState], catalog: ContentCatalog, levels: [CEFRLevel]) -> [LevelMemory] {
        let byID = Dictionary(reviews.map { ($0.cardID, $0) }, uniquingKeysWith: { first, _ in first })
        return levels.map { level in
            let cards = catalog.cards.filter { $0.level == level && byID[$0.id]?.status != .suspended }
            let longTerm = cards.filter { card in
                guard let r = byID[card.id] else { return false }
                return r.status == .review && r.interval >= StatsConstants.longTermIntervalDays
            }.count
            return LevelMemory(level: level, longTerm: longTerm, total: cards.count)
        }
    }
}
