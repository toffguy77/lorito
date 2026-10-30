import Foundation

/// Deterministic demo user data for App Store screenshots (UI tests launched
/// with `-lorito-demo-data`): onboarding done, A1 in long-term memory, A2 in
/// progress, a few reviews due today, a 12-day streak, 12 weeks of history, a DELE A2
/// date in 74 days and the conjugation and words trainers on.
/// Never used outside UI testing.
public struct DemoSeed: Sendable {
    public var settings: UserSettings
    public var reviews: [ReviewState]
    public var events: [StudyEvent]
    public var trapPractice: [TrapPracticeEvent] = []
    public var mockAttempts: [MockAttempt] = []

    public static let streakDays = 12

    public static func make(catalog: ContentCatalog, today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: start) ?? start }

        var settings = UserSettings(targetLevel: .b1, dailyNewCardCount: 3, didCompleteOnboarding: true)
        // Screenshots show the goal countdown and today's trainers too.
        settings.exam = ExamGoal(kind: .deleA2, date: day(74))
        settings.dailyConjugationCount = 3
        settings.dailyNewWordCount = 5
        settings.variantPromptAnswered = true

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

    /// personal-traps UI test: A1-07 failed two days ago, «Ясно» yesterday —
    /// one more «Ясно» today resolves it.
    public static func trapClearedOnce(today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        func at(_ days: Int) -> Date { calendar.date(byAdding: .hour, value: 10 - days * 24, to: start) ?? start }
        let review = ReviewState(cardID: "A1-07", interval: 1, repetitions: 0,
                                 dueDate: calendar.date(byAdding: .day, value: 5, to: start) ?? start, status: .learning)
        var seed = DemoSeed(settings: UserSettings(targetLevel: .a1, didCompleteOnboarding: true), reviews: [review],
                            events: [StudyEvent(cardID: "A1-07", date: at(2), grade: Grade.again.rawValue)])
        seed.trapPractice = [TrapPracticeEvent(cardID: "A1-07", date: at(1), outcome: .clear)]
        return seed
    }

    /// conjugation-trainer UI test: the futuro-simple card (A2-07) studied, trainer
    /// on with quota 1 → today's single item is `conj:ser:futuro-simple`.
    public static func conjugationReady(today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        var settings = UserSettings(targetLevel: .a2, didCompleteOnboarding: true)
        settings.dailyConjugationCount = 1
        let review = ReviewState(cardID: "A2-07", interval: 10, repetitions: 2,
                                 dueDate: calendar.date(byAdding: .day, value: 8, to: start) ?? start, status: .review)
        return DemoSeed(settings: settings, reviews: [review], events: [])
    }

    /// weekly-recap UI test: study last week, every A1 card long-term → recap + "A1 закрыт".
    public static func recapAndMilestone(catalog: ContentCatalog, today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        let start = calendar.startOfDay(for: today)
        let weekAgo = calendar.date(byAdding: .day, value: -8, to: start) ?? start
        let reviews = catalog.cards(in: .a1).map {
            ReviewState(cardID: $0.id, interval: 30, repetitions: 5,
                        dueDate: calendar.date(byAdding: .day, value: 15, to: start) ?? start, status: .review)
        }
        let events = catalog.cards(in: .a1).prefix(3).enumerated().map { i, card in
            StudyEvent(cardID: card.id, date: calendar.date(byAdding: .hour, value: 10 + i, to: weekAgo) ?? weekAgo,
                       grade: Grade.good.rawValue)
        }
        return DemoSeed(settings: UserSettings(targetLevel: .a1, didCompleteOnboarding: true), reviews: reviews,
                        events: Array(events))
    }

    /// exam-path UI test: a DELE A2 mock left running two hours ago (time ran out while away).
    public static func expiredMock(today: Date) -> DemoSeed {
        var seed = DemoSeed(settings: UserSettings(targetLevel: .a2, didCompleteOnboarding: true), reviews: [], events: [])
        seed.mockAttempts = [MockAttempt(examID: "dele-a2", form: 0, startedAt: today.addingTimeInterval(-2 * 3600))]
        return seed
    }

    /// vocabulary UI test: words on, «casa» in the personal deck, passed on two days → production.
    public static func wordsProduction(today: Date, calendar: Calendar = .learningDay) -> DemoSeed {
        var settings = UserSettings(targetLevel: .a1, didCompleteOnboarding: true)
        settings.dailyNewWordCount = 5
        settings.personalWordIDs = ["casa"]
        let start = calendar.startOfDay(for: today)
        let events = [-3, -1].map {
            StudyEvent(cardID: "word:casa", date: calendar.date(byAdding: .hour, value: 10 + $0 * 24, to: start) ?? start,
                       grade: Grade.good.rawValue)
        }
        return DemoSeed(settings: settings, reviews: [], events: events)
    }

    /// Writes the seed into an (empty, in-memory) store.
    public func apply(to store: UserDataStore) throws {
        try store.saveSettings(settings)
        for r in reviews { try store.upsertReview(r) }
        for e in events { try store.appendEvent(e) }
        for p in trapPractice { try store.appendTrapPractice(p) }
        for a in mockAttempts { try store.upsertMockAttempt(a) }
    }
}
