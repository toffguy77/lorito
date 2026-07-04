import Testing
import Foundation
@testable import Domain

private func utcCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

private func dateTime(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    utcCalendar().date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Suite("Reminder config")
struct ReminderConfigTests {
    @Test("Enabling with a time persists enabled and the time via UserSettings")
    func enablePersists() {
        var settings = UserSettings.default
        var config = settings.reminderConfig
        config.enable(defaultTime: ReminderTime(hour: 20, minute: 0))
        settings.reminderConfig = config
        #expect(settings.remindersEnabled)
        #expect(settings.reminderMinutes == [20 * 60])
        #expect(settings.reminderConfig.times == [ReminderTime(hour: 20, minute: 0)])
    }

    @Test("Multiple distinct times are retained and ordered")
    func multipleTimes() {
        var config = ReminderConfig(enabled: true, times: [ReminderTime(hour: 20, minute: 0)])
        config.addTime(ReminderTime(hour: 9, minute: 0))
        config.addTime(ReminderTime(hour: 9, minute: 0))  // duplicate ignored
        #expect(config.times == [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 20, minute: 0)])
    }

    @Test("Cannot remove the last time while enabled; disabling clears intent")
    func guardrails() {
        var config = ReminderConfig(enabled: true, times: [ReminderTime(hour: 8, minute: 0)])
        config.removeTime(ReminderTime(hour: 8, minute: 0))  // ignored — last one while enabled
        #expect(config.times.count == 1)
        config.disable()
        #expect(!config.enabled)
    }
}

@Suite("Reminder planner")
struct ReminderPlannerTests {
    let cal = utcCalendar()
    let now = dateTime(2026, 6, 24, 6, 0)  // 06:00, before all test times
    let times = [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 20, minute: 0)]

    private func uniform(_ due: Int, _ new: Int) -> (Date) -> DayCounts {
        { _ in DayCounts(due: due, new: new) }
    }

    @Test("Identical inputs produce identical requests")
    func deterministic() {
        let a = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(3, 1))
        let b = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(3, 1))
        #expect(a == b)
    }

    @Test("One request per future configured time, at the local time")
    func requestPerTime() {
        let reqs = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(2, 0))
        // Day 0 has two future times (09:00, 20:00).
        let day0 = reqs.filter { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 24)) }
        #expect(day0.count == 2)
        let comps = day0.map { cal.dateComponents([.hour, .minute], from: $0.fireDate) }
        #expect(comps.contains { $0.hour == 9 && $0.minute == 0 })
        #expect(comps.contains { $0.hour == 20 && $0.minute == 0 })
    }

    @Test("Past times today are excluded")
    func futureOnly() {
        let afterNine = dateTime(2026, 6, 24, 10, 0)
        let reqs = ReminderPlanner.requests(times: times, now: afterNine, calendar: cal, counts: uniform(1, 0))
        let day0 = reqs.filter { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 24)) }
        // Only 20:00 remains today; 09:00 is in the past.
        #expect(day0.count == 1)
        #expect(cal.component(.hour, from: day0[0].fireDate) == 20)
    }

    @Test("A day with zero counts yields no request; other days unaffected")
    func skipEmptyDay() {
        // Empty only on day 1 (2026-06-25); other days have cards.
        let counts: (Date) -> DayCounts = { day in
            cal.isDate(day, inSameDayAs: dateTime(2026, 6, 25)) ? DayCounts(due: 0, new: 0) : DayCounts(due: 1, new: 0)
        }
        let reqs = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: counts)
        #expect(!reqs.contains { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 25)) })
        #expect(reqs.contains { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 26)) })
    }

    @Test("Bodies reflect counts in Russian, including reviews-only")
    func bodies() {
        #expect(ReminderPlanner.body(due: 5, new: 1) == "5 на повторение + 1 новых")
        #expect(ReminderPlanner.body(due: 5, new: 0) == "5 на повторение")
        #expect(ReminderPlanner.body(due: 0, new: 3) == "3 новых карточек")
    }

    @Test("Output is bounded to ≤64, keeping the soonest")
    func boundedToLimit() {
        // 9 times/day × 7 days = 63 candidate requests, all non-empty.
        let many = (8...16).map { ReminderTime(hour: $0, minute: 0) }
        let reqs = ReminderPlanner.requests(times: many, now: now, calendar: cal, counts: uniform(1, 1))
        #expect(reqs.count <= ReminderConstants.maxPendingReminders)
        // Sorted soonest-first.
        #expect(reqs == reqs.sorted { $0.fireDate < $1.fireDate })
    }

    @Test("All identifiers use the reserved prefix")
    func prefixed() {
        let reqs = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(1, 1))
        #expect(reqs.allSatisfy { $0.id.hasPrefix(ReminderConstants.identifierPrefix) })
        #expect(reqs.allSatisfy { $0.route == ReminderRoute.today })
    }
}

@Suite("Reminder planner — streak awareness")
struct ReminderPlannerStreakTests {
    let cal = utcCalendar()
    let now = dateTime(2026, 6, 24, 6, 0)  // 06:00, before all test times
    let times = [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 20, minute: 0)]

    private func uniform(_ due: Int, _ new: Int) -> (Date) -> DayCounts {
        { _ in DayCounts(due: due, new: new) }
    }

    private func uniformStreak(_ streak: Int, _ studiedToday: Bool) -> (Date) -> DayStreak {
        { _ in DayStreak(currentStreak: streak, studiedToday: studiedToday) }
    }

    // MARK: - Body composition

    @Test("Active streak weaves a Russian streak line into the counts body")
    func streakLineWoven() {
        let body = ReminderPlanner.body(due: 3, new: 0, streak: 5)
        #expect(body.contains("5"))
        #expect(body.contains("3 на повторение"))
        #expect(body.contains("🔥"))
    }

    @Test("Zero streak leaves the counts body unchanged")
    func noStreakLine() {
        #expect(ReminderPlanner.body(due: 5, new: 1, streak: 0) == "5 на повторение + 1 новых")
        #expect(ReminderPlanner.body(due: 5, new: 0) == "5 на повторение")
    }

    @Test("Empty counts with a streak produce a save-streak nudge body")
    func saveStreakBody() {
        let body = ReminderPlanner.body(due: 0, new: 0, streak: 4)
        #expect(body.contains("4"))
        #expect(body.contains("🔥"))
        // Не заявляет о карточках на повторение.
        #expect(!body.contains("на повторение"))
    }

    @Test("Russian day word agrees with the streak count")
    func dayWordAgreement() {
        #expect(ReminderPlanner.body(due: 1, new: 0, streak: 1).contains("1 день"))
        #expect(ReminderPlanner.body(due: 1, new: 0, streak: 3).contains("3 дня"))
        #expect(ReminderPlanner.body(due: 1, new: 0, streak: 5).contains("5 дней"))
    }

    // MARK: - Narrowed skip rule

    @Test("Empty day with streak at risk fires a save-streak nudge today")
    func atRiskFiresNudge() {
        let reqs = ReminderPlanner.requests(
            times: times, now: now, calendar: cal,
            counts: uniform(0, 0), streak: uniformStreak(5, false)
        )
        let day0 = reqs.filter { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 24)) }
        #expect(!day0.isEmpty)
        #expect(day0.allSatisfy { !$0.body.contains("на повторение") })
        #expect(day0.allSatisfy { $0.body.contains("🔥") })
    }

    @Test("Empty day, streak not at risk (already studied today) yields no request")
    func studiedTodaySkips() {
        let reqs = ReminderPlanner.requests(
            times: times, now: now, calendar: cal,
            counts: uniform(0, 0), streak: uniformStreak(5, true)
        )
        #expect(reqs.isEmpty)
    }

    @Test("Empty day, zero streak yields no request (unchanged skip)")
    func zeroStreakSkips() {
        let reqs = ReminderPlanner.requests(
            times: times, now: now, calendar: cal,
            counts: uniform(0, 0), streak: uniformStreak(0, false)
        )
        #expect(reqs.isEmpty)
    }

    @Test("Save-streak nudge is limited to today, not future empty days")
    func nudgeOnlyToday() {
        // Streak at risk on every day, but only today should nudge on empty days.
        let reqs = ReminderPlanner.requests(
            times: times, now: now, calendar: cal,
            counts: uniform(0, 0), streak: uniformStreak(5, false)
        )
        let future = reqs.filter { !cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 24)) }
        #expect(future.isEmpty)
    }

    // MARK: - Determinism with the new input

    @Test("Identical inputs incl. streak produce identical requests")
    func deterministicWithStreak() {
        let a = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(3, 1), streak: uniformStreak(2, false))
        let b = ReminderPlanner.requests(times: times, now: now, calendar: cal, counts: uniform(3, 1), streak: uniformStreak(2, false))
        #expect(a == b)
    }

    @Test("Non-empty future days still schedule and may show the streak line")
    func futureDaysUnaffected() {
        let reqs = ReminderPlanner.requests(
            times: times, now: now, calendar: cal,
            counts: uniform(2, 0), streak: uniformStreak(6, false)
        )
        #expect(reqs.contains { cal.isDate($0.fireDate, inSameDayAs: dateTime(2026, 6, 26)) })
    }
}
