import Foundation
import Testing
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)

private func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

private func graded(_ date: Date, _ id: String = "A1-01") -> StudyEvent {
    StudyEvent(cardID: id, date: date, grade: "good")
}

private let today = at(2026, 10, 27)

@Suite("Daily activity series")
struct DailyActivityTests {
    @Test("84 entries, oldest first, last is today")
    func lengthAndOrder() {
        let series = StatsCalculator.dailyActivity(events: [], days: 84, today: today, calendar: cal)
        #expect(series.count == 84)
        #expect(cal.isDate(series.last!.day, inSameDayAs: today))
        #expect(cal.dateComponents([.day], from: series.first!.day, to: cal.startOfDay(for: today)).day == 83)
        #expect(zip(series, series.dropFirst()).allSatisfy { $0.day < $1.day })
    }

    @Test("Counts grade events per day; days without study are 0")
    func counts() {
        let events = [graded(today), graded(today), graded(at(2026, 10, 25)),
                      StudyEvent(cardID: "A1-02", date: today, grade: nil),   // not a grade
                      graded(at(2026, 1, 1))]                                  // outside window
        let series = StatsCalculator.dailyActivity(events: events, days: 84, today: today, calendar: cal)
        #expect(series[83].count == 2)
        #expect(series[82].count == 0)
        #expect(series[81].count == 1)
        #expect(series.map(\.count).reduce(0, +) == 3)
    }

    @Test("Event just before midnight counts on the same day as the streak")
    func midnightBoundary() {
        let lateYesterday = at(2026, 10, 26, 23, 59)
        let events = [graded(lateYesterday)]
        let series = StatsCalculator.dailyActivity(events: events, days: 7, today: today, calendar: cal)
        #expect(series[5].count == 1)   // yesterday
        #expect(series[6].count == 0)   // today
        let stats = StatsCalculator.compute(events: events, today: today, calendar: cal)
        #expect(stats.currentStreak == 1)  // the streak also places it yesterday
    }
}

@Suite("Activity buckets")
struct ActivityBucketTests {
    @Test("Zeros map to bucket 0")
    func zeros() {
        #expect(StatsCalculator.buckets(for: [0, 0, 0]) == [0, 0, 0])
    }

    @Test("Quartiles over non-zero counts")
    func quartiles() {
        #expect(StatsCalculator.buckets(for: [0, 1, 2, 3, 4]) == [0, 1, 2, 3, 3])
        // Non-zero [1, 1, 1, 10]: Q1 = 1, Q3 = 1 → every value ≥ Q3.
        #expect(StatsCalculator.buckets(for: [1, 1, 1, 10, 0]) == [3, 3, 3, 3, 0])
    }

    @Test("A single non-zero value, or all ties, fall into bucket 3")
    func ties() {
        #expect(StatsCalculator.buckets(for: [0, 5, 0]) == [0, 3, 0])
        #expect(StatsCalculator.buckets(for: [2, 2, 2]) == [3, 3, 3])
    }

    @Test("Wide spread uses all three buckets")
    func spread() {
        let counts = [1, 2, 3, 4, 5, 6, 7, 8]
        let b = StatsCalculator.buckets(for: counts)
        #expect(Set(b) == [1, 2, 3])
        #expect(b == b.sorted())   // monotonic in count
    }
}

@Suite("Long-term memory")
struct LongTermMemoryTests {
    static func card(_ id: String, _ level: CEFRLevel) -> Card {
        Card(id: id, level: level, themeID: "t", order: Int(id.suffix(2))!, title: id, body: "")
    }

    static let catalog = ContentCatalog(themes: [], cards: [
        card("A1-01", .a1), card("A1-02", .a1), card("A1-03", .a1), card("A1-04", .a1),
        card("A2-01", .a2), card("B1-01", .b1),
    ])

    @Test("Threshold 21 inclusive; suspended excluded; only included levels")
    func memory() {
        let reviews = [
            ReviewState(cardID: "A1-01", interval: 21, repetitions: 5, status: .review),
            ReviewState(cardID: "A1-02", interval: 20, repetitions: 5, status: .review),
            ReviewState(cardID: "A1-03", interval: 40, repetitions: 5, status: .suspended),
            ReviewState(cardID: "A2-01", interval: 30, repetitions: 5, status: .learning),
        ]
        let rows = StatsCalculator.longTermMemory(reviews: reviews, catalog: Self.catalog, levels: [.a1, .a2])
        #expect(rows.map(\.level) == [.a1, .a2])
        #expect(rows[0].longTerm == 1)
        #expect(rows[0].total == 3)        // A1-03 suspended → excluded from total
        #expect(rows[1].longTerm == 0)     // learning, not review
        #expect(rows[1].total == 1)
        #expect(StatsConstants.longTermIntervalDays == 21)
    }
}
