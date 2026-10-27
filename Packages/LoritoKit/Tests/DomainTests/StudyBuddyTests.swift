import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private func date(_ d: Int, _ h: Int = 10) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h))! }
private let today = date(27)
private func key(_ d: Int) -> String { BuddyDayKey.key(date(d), calendar: cal) }
private func day(_ owner: String, _ d: Int, studied: Bool = true) -> BuddyDay {
    BuddyDay(owner: owner, day: key(d), studied: studied, gradedCount: studied ? 5 : 0, currentStreak: 0, displayName: owner)
}
private func streak(_ mine: [Int], _ theirs: [Int], frozen: [Int] = []) -> Int {
    SharedStreakCalculator.streak(mine: mine.map { day("me", $0) } + frozen.map { day("me", $0, studied: false) },
                                  theirs: theirs.map { day("you", $0) }, today: today, calendar: cal)
}

@Suite("Study buddy: shared streak")
struct SharedStreakTests {
    @Test("Day keys are local learning days, yyyy-MM-dd")
    func keys() {
        #expect(key(27) == "2026-10-27")
        #expect(BuddyDayKey.key(date(27, 23), calendar: cal) == "2026-10-27")
    }

    @Test("Both studied N days → N; deterministic")
    func both() {
        #expect(streak([25, 26, 27], [25, 26, 27]) == 3)
        #expect(streak([25, 26, 27], [25, 26, 27]) == streak([27, 26, 25], [26, 27, 25]))
    }

    @Test("A gap on either side breaks it (missed day before yesterday → at most 2)")
    func gap() {
        #expect(streak([26, 27], [25, 26, 27]) == 2)
        #expect(streak([24, 26, 27], [24, 25, 26, 27]) == 2)
        #expect(streak([27], [26]) == 0)
    }

    @Test("Today not done by both yet → counts to yesterday")
    func todayIncomplete() {
        #expect(streak([25, 26, 27], [25, 26]) == 2)
        #expect(streak([25, 26], [25, 26]) == 2)
    }

    @Test("A freeze day (kept personal streak, no study) breaks the shared streak")
    func freeze() {
        #expect(streak([25, 27], [25, 26, 27], frozen: [26]) == 1)
    }
}

@Suite("Study buddy: nudge rule")
struct NudgeRuleTests {
    @Test("Once per sender per day; never after the partner studied that day")
    func rule() {
        let partnerNotYet = day("you", 27, studied: false)
        #expect(NudgeRule.canNudge(from: "me", sent: [], partnerDays: [partnerNotYet], today: today, calendar: cal))
        #expect(NudgeRule.canNudge(from: "me", sent: [], partnerDays: [], today: today, calendar: cal))
        let sent = BuddyNudge(from: "me", day: key(27))
        #expect(!NudgeRule.canNudge(from: "me", sent: [sent], partnerDays: [], today: today, calendar: cal))
        #expect(NudgeRule.canNudge(from: "me", sent: [BuddyNudge(from: "me", day: key(26))], partnerDays: [],
                                   today: today, calendar: cal))
        #expect(NudgeRule.canNudge(from: "me", sent: [BuddyNudge(from: "you", day: key(27))], partnerDays: [],
                                   today: today, calendar: cal))
        #expect(!NudgeRule.canNudge(from: "me", sent: [], partnerDays: [day("you", 27)], today: today, calendar: cal))
        #expect(BuddyNudge(from: "me", day: key(27)).recordName == "me:2026-10-27")
    }
}

@Suite("Study buddy: published aggregates")
struct BuddyAggregateTests {
    @Test("Last 14 learning days from the log: studied, graded count, streak as of that day; nothing about cards")
    func aggregates() {
        let events = [StudyEvent(cardID: "A1-01", date: date(26), grade: "good"),
                      StudyEvent(cardID: "A1-02", date: date(26), grade: "again"),
                      StudyEvent(cardID: "conj:ser:presente", date: date(27), grade: "good"),
                      StudyEvent(cardID: "A1-03", date: date(1), grade: "good")]
        let days = BuddyAggregate.days(events: events, today: today, owner: "me", displayName: "Аня", calendar: cal)
        #expect(days.count == 14)
        #expect(days.last == BuddyDay(owner: "me", day: "2026-10-27", studied: true, gradedCount: 1, currentStreak: 2,
                                      displayName: "Аня"))
        #expect(days[days.count - 2].gradedCount == 2 && days[days.count - 2].currentStreak == 1)
        #expect(days.first?.day == "2026-10-14" && days.first?.studied == false)
        #expect(BuddyDay(owner: "me", day: "2026-10-27", studied: true, gradedCount: 1, currentStreak: 2,
                         displayName: "Аня").recordName == "me:2026-10-27")
    }

    @Test("Last seven days strip for the partner (oldest first), missing days not studied")
    func strip() {
        let strip = BuddyAggregate.lastSeven([day("you", 27), day("you", 25)], today: today, calendar: cal)
        #expect(strip.map(\.studied) == [false, false, false, false, true, false, true])
        #expect(strip.last?.day == "2026-10-27")
    }
}
