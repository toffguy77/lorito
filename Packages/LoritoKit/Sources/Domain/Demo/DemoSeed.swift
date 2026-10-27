import Foundation

/// Deterministic demo user data for App Store screenshots (UI tests launched
/// with `-lorito-demo-data`): onboarding done, A1 in long-term memory, A2 in
/// progress, a few reviews due today, a 12-day streak and 12 weeks of history.
/// Never used outside UI testing.
public struct DemoSeed: Sendable {
    public var settings: UserSettings
    public var reviews: [ReviewState]
    public var events: [StudyEvent]

    public static let streakDays = 12

    public static func make(catalog: ContentCatalog, today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: start) ?? start }

        let settings = UserSettings(targetLevel: .b1, dailyNewCardCount: 3, didCompleteOnboarding: true)

        var reviews: [ReviewState] = []
        func add(_ card: Card, interval: Int, dueIn: Int, reps: Int) {
            let due = day(dueIn)
            reviews.append(ReviewState(
                cardID: card.id, easeFactor: 2.5, interval: interval, repetitions: reps, dueDate: due,
                lastGrade: Grade.good.rawValue, status: .review, stability: Double(interval), difficulty: 5,
                lastReviewDate: day(dueIn - interval), schedulerVersion: FSRSScheduler.version, fsrsDueDate: due))
        }
        // A1: mostly long-term (≥ 21 days), a couple due today.
        for (i, card) in catalog.cards(in: .a1).enumerated() {
            if i % 10 == 3 { add(card, interval: 9, dueIn: 0, reps: 4) }
            else { add(card, interval: 24 + (i * 7) % 40, dueIn: 1 + (i * 5) % 20, reps: 5) }
        }
        // A2: the first half in progress, a few due today.
        for (i, card) in catalog.cards(in: .a2).prefix(16).enumerated() {
            if i % 4 == 1 { add(card, interval: 3, dueIn: 0, reps: 2) }
            else { add(card, interval: 4 + i % 9, dueIn: 1 + i % 6, reps: 3) }
        }

        // History: every day of the streak (yesterday back), ~2/3 of the days before.
        let ids = reviews.map(\.cardID)
        var events: [StudyEvent] = []
        for offset in 1...84 {
            if offset == streakDays + 1 { continue }                 // the gap before the streak
            if offset > streakDays, offset % 3 == 0 { continue }     // older history: 2 of 3 days
            let count = 4 + (offset * 5) % 9
            let date = calendar.date(byAdding: .hour, value: 19, to: day(-offset)) ?? day(-offset)
            for k in 0..<count {
                let grade: Grade = (offset + k) % 7 == 0 ? .hard : .good
                events.append(StudyEvent(cardID: ids[(offset * 3 + k) % ids.count], date: date, grade: grade.rawValue))
            }
        }
        return DemoSeed(settings: settings, reviews: reviews, events: events)
    }

    /// streak-protection UI test: 10 studied days ending the day before
    /// yesterday, yesterday missed (frozen by the freeze those days earned).
    public static func frozenYesterday(catalog: ContentCatalog, today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        let card = catalog.cards.first?.id ?? "A1-01"
        let events = (2...11).map { offset in
            StudyEvent(cardID: card, date: calendar.date(byAdding: .hour, value: 19 - offset * 24, to: start) ?? start,
                       grade: Grade.good.rawValue)
        }
        let review = ReviewState(cardID: card, interval: 30, repetitions: 5,
                                 dueDate: calendar.date(byAdding: .day, value: 20, to: start) ?? start, status: .review)
        return DemoSeed(settings: UserSettings(targetLevel: .a1, didCompleteOnboarding: true), reviews: [review], events: events)
    }

    /// Writes the seed into an (empty, in-memory) store.
    public func apply(to store: UserDataStore) throws {
        try store.saveSettings(settings)
        for r in reviews { try store.upsertReview(r) }
        for e in events { try store.appendEvent(e) }
    }
}
