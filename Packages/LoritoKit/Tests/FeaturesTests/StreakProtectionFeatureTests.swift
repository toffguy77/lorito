import Foundation
import Testing
import Domain
@testable import Features

private let cal = Calendar.learningDay
private func ev(_ daysAgo: Int, now: Date) -> StudyEvent {
    StudyEvent(cardID: "A1-01", date: cal.date(byAdding: .day, value: -daysAgo, to: now)!, grade: "good")
}

@Suite("Streak protection on Today")
@MainActor
struct StreakProtectionFeatureTests {
    let now = Date()

    @Test("Freeze banner once after a frozen day; revival banner while in progress")
    func banners() {
        let ledger = StreakBannerLedger(defaults: UserDefaults(suiteName: "lorito.tests.\(UUID().uuidString)")!)
        let frozenLog = (2...11).map { ev($0, now: now) }               // 10 days, yesterday missed (frozen)
        #expect(ledger.banner(events: frozenLog, today: now, keepFrozen: false) == .frozen)
        #expect(ledger.banner(events: frozenLog, today: now, keepFrozen: false) == .frozen) // not seen yet
        ledger.markFrozenShown(today: now)
        #expect(ledger.banner(events: frozenLog, today: now, keepFrozen: false) == nil)    // later visits
        #expect(ledger.banner(events: frozenLog, today: now, keepFrozen: true) == .frozen) // same visit

        // 40 studied days, two frozen, then lost; one day of the revival done.
        let lost = (4...43).map { ev($0, now: now) } + [ev(0, now: now)]
        let banner = ledger.banner(events: lost, today: now, keepFrozen: false)
        #expect(banner == .revival(lost: 40, daysLeft: 2))
        #expect(banner?.detail == "Ещё 2 дня занятий подряд — и серия 40 дней вернётся.")
    }

    @Test("Foreground refresh reschedules reminders")
    func foreground() async {
        var calls: [String] = []
        await ForegroundRefresh.run(publishWidgets: { calls.append("widgets") },
                                    flushAnalytics: { calls.append("flush") },
                                    rescheduleReminders: { calls.append("reschedule") })
        #expect(calls.contains("reschedule") && calls.contains("widgets"))
    }
}
