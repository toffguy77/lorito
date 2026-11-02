import Foundation
import Testing
import Domain
import Content
import Persistence

@Suite("Demo seed (App Store screenshots)")
struct DemoSeedTests {
    let utc = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
    var today: Date { utc.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 10))! }

    @Test("Full, deterministic data: streak, history, long-term memory, work due today")
    func content() throws {
        let catalog = try ContentLoader.loadCatalog()
        let a = DemoSeed.make(catalog: catalog, today: today, calendar: utc)
        let b = DemoSeed.make(catalog: catalog, today: today, calendar: utc)
        #expect(a.reviews == b.reviews && a.events.map(\.date) == b.events.map(\.date))
        #expect(a.settings.didCompleteOnboarding && a.settings.targetLevel == .b1)
        #expect(a.settings.exam?.kind == .deleA2 && a.settings.dailyConjugationCount > 0 && a.settings.dailyNewWordCount > 0)

        let stats = StatsCalculator.compute(events: a.events, today: today, calendar: utc)
        #expect(stats.currentStreak > DemoSeed.streakDays)            // today studied too
        #expect(stats.studiedToday == DemoSeed.studiedToday)
        #expect(!DueSelection.dueCards(from: a.reviews, on: today, calendar: utc).isEmpty)
        #expect(a.reviews.contains { $0.interval >= StatsConstants.longTermIntervalDays })
        #expect(a.reviews.allSatisfy { FSRSScheduler.hasValidMemory($0) })
        #expect(Set(a.events.map { utc.startOfDay(for: $0.date) }).count > 40)
    }

    @Test("Store media show this week's activity, no zeros (app-store-presence)")
    func currentWeek() throws {
        let catalog = try ContentLoader.loadCatalog()
        let seed = DemoSeed.make(catalog: catalog, today: today, calendar: utc)
        let recap = WeeklyRecap.make(events: seed.events, reviews: seed.reviews, practice: [], catalog: catalog,
                                     settings: seed.settings, today: today, calendar: utc)
        #expect(recap.newRules > 0)
        #expect(StatsCalculator.compute(events: seed.events, today: today, calendar: utc).studiedToday > 0)
        #expect(seed.events.allSatisfy { $0.date <= today })
    }

    @Test("The session opens on a Russian-speaker trap: A1-07 (noun gender), with work still planned")
    func firstSessionCard() throws {
        let catalog = try ContentLoader.loadCatalog()
        let seed = DemoSeed.make(catalog: catalog, today: today, calendar: utc)
        let plan = DailyPlanner.composePlan(DailyPlanRequest(cards: catalog.cards, reviews: seed.reviews,
                                                             settings: seed.settings, today: today,
                                                             events: seed.events, calendar: utc))
        #expect(plan.queue.first?.cardID == DemoSeed.firstCardID)
        #expect(plan.counts.dueCount > 0 && plan.counts.newCount > 0)
    }

    @Test("Applies to an empty store")
    func apply() throws {
        let catalog = try ContentLoader.loadCatalog()
        let seed = DemoSeed.make(catalog: catalog, today: today, calendar: utc)
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
        try seed.apply(to: store)
        #expect(try store.allReviews().count == seed.reviews.count)
        #expect(try store.allEvents().count == seed.events.count)
        #expect(try store.loadSettings().didCompleteOnboarding)
    }
}
