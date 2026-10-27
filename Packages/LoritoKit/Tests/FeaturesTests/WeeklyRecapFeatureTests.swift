import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

@Suite("Weekly recap and milestones on Today")
@MainActor
struct WeeklyRecapFeatureTests {
    @Test("Share content: brand-free numbers / level, month and year only — no personal data")
    func shareContent() {
        let m = ShareCardContent.milestone(.a1, date: Date(timeIntervalSince1970: 1_790_000_000))
        #expect(m.headline == "A1 закрыт" && m.lines.first == "уровень пройден в Lorito")
        let r = WeeklyRecap(weekStart: Date(timeIntervalSince1970: 1_790_000_000), weekID: "2026-W43", daysStudied: 5,
                            newRules: 2, longTerm: 31, topTrapCardID: "A1-07")
        let c = ShareCardContent.recap(r)
        #expect(c.lines == ["5 дней занятий", "2 новых правила", "31 в долгой памяти"])
        let all = ([c.headline, c.monthYear] + c.lines).joined(separator: " ")
        #expect(!all.contains("A1-07"))          // no card ids, names or device data
    }

    @Test("Recap shows once (lastRecapWeek written on appear); milestone celebrated once")
    func once() throws {
        let catalog = try ContentLoader.loadCatalog()
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)),
                                           localMirror: nil)
        try store.saveSettings(UserSettings(targetLevel: .a1, didCompleteOnboarding: true))
        let now = Date()
        let lastWeek = Calendar.learningDay.date(byAdding: .day, value: -8, to: now)!
        try store.appendEvent(StudyEvent(cardID: "A1-01", date: lastWeek, grade: "good"))
        for c in catalog.cards(in: .a1) {
            try store.upsertReview(ReviewState(cardID: c.id, interval: 30, repetitions: 5, status: .review))
        }
        let defaults = { UserDefaults(suiteName: "lorito.tests.\(UUID().uuidString)")! }
        func today() -> TodayModel {
            TodayModel(store: store, catalog: catalog, boosts: FirstSessionBoostStore(defaults: defaults()),
                       prompts: TodayPromptSlot(defaults: defaults()), goals: TodayGoalBuilder(defaults: defaults()),
                       streak: StreakBannerLedger(defaults: defaults()))
        }
        let first = today()
        #expect(first.recap != nil && first.milestone == .a1)
        first.markShownOnAppear()
        first.refresh()
        #expect(first.recap != nil && first.milestone == .a1)        // same visit keeps showing
        let later = today()
        #expect(later.recap == nil && later.milestone == nil)
        #expect(try store.loadSettings().celebratedLevels == [.a1])
    }
}
