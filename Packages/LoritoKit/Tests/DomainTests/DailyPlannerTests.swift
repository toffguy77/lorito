import Testing
import Foundation
@testable import Domain

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: m, day: d))!
}

private func card(
    _ id: String,
    level: CEFRLevel = .a1,
    theme: String = "a1-1",
    order: Int,
    related: [String] = []
) -> Card {
    Card(id: id, level: level, themeID: theme, order: order, title: id, related: related, body: "")
}

private func review(
    _ id: String,
    due: Date,
    status: ReviewStatus
) -> ReviewState {
    ReviewState(cardID: id, dueDate: due, status: status)
}

private func settings(
    target: CEFRLevel? = .a1,
    themes: [String] = [],
    newPerDay: Int = 1
) -> UserSettings {
    UserSettings(targetLevel: target, selectedThemeIDs: themes, dailyNewCardCount: newPerDay)
}

private let today = day(2026, 6, 24)

private func dueIDs(_ plan: DailyPlan) -> [String] {
    plan.queue.filter { $0.kind == .due }.map(\.cardID)
}
private func newIDs(_ plan: DailyPlan) -> [String] {
    plan.queue.filter { $0.kind == .new }.map(\.cardID)
}

// MARK: - 2. Due selection

@Suite("Daily plan — due selection")
struct DailyPlanDueTests {
    @Test("Due review and learning cards are included; not-yet-due, suspended, no-state excluded")
    func dueMembership() {
        let cards = [
            card("A1-01", order: 1), card("A1-02", order: 2),
            card("A1-03", order: 3), card("A1-04", order: 4),
            card("A1-05", order: 5),
        ]
        let reviews = [
            review("A1-01", due: day(2026, 6, 20), status: .review),   // due
            review("A1-02", due: day(2026, 6, 24), status: .learning),  // due today
            review("A1-03", due: day(2026, 6, 30), status: .review),    // not yet due
            review("A1-04", due: day(2026, 6, 1), status: .suspended),  // suspended
            // A1-05 has no review state
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today)
        )
        #expect(dueIDs(plan) == ["A1-01", "A1-02"])
    }

    @Test("Due cards ordered by dueDate ascending, then id ascending")
    func dueOrdering() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2), card("A1-03", order: 3)]
        let reviews = [
            review("A1-03", due: day(2026, 6, 22), status: .review),
            review("A1-01", due: day(2026, 6, 20), status: .review),
            review("A1-02", due: day(2026, 6, 20), status: .review),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today)
        )
        // 6/20 ties broken by id (A1-01, A1-02), then 6/22 (A1-03).
        #expect(dueIDs(plan) == ["A1-01", "A1-02", "A1-03"])
    }
}

// MARK: - 3. New selection — scope & limit

@Suite("Daily plan — new scope and limit")
struct DailyPlanNewScopeTests {
    @Test("Above-target excluded; lower level in scope; out-of-theme excluded; reviewed not new")
    func eligibility() {
        let cards = [
            card("A2-01", level: .a2, theme: "a2-1", order: 1),  // in scope (target B1)
            card("B2-01", level: .b2, theme: "b2-1", order: 1),  // above target
            card("B1-09", level: .b1, theme: "b1-9", order: 9),  // out of selected theme
            card("B1-01", level: .b1, theme: "b1-1", order: 1),  // already reviewed
            card("B1-02", level: .b1, theme: "b1-1", order: 2),  // eligible
        ]
        let reviews = [review("B1-01", due: day(2026, 6, 1), status: .review)]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(
                cards: cards, reviews: reviews,
                settings: settings(target: .b1, themes: ["a2-1", "b1-1"], newPerDay: 10),
                today: today
            )
        )
        // Only A2-01 and B1-02 are eligible (B1-01 reviewed, B2-01 above, B1-09 unselected theme).
        #expect(Set(newIDs(plan)) == ["A2-01", "B1-02"])
    }

    @Test("dailyNewCardCount caps introductions; lower order wins")
    func limitAndOrder() {
        let cards = [card("A1-03", order: 3), card("A1-07", order: 7), card("A1-05", order: 5)]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 1), today: today)
        )
        #expect(newIDs(plan) == ["A1-03"])
    }

    @Test("Fewer eligible than the limit introduces all of them")
    func fewerThanLimit() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2)]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 5), today: today)
        )
        #expect(newIDs(plan) == ["A1-01", "A1-02"])
    }
}

// MARK: - 4. Related prerequisites

@Suite("Daily plan — related prerequisites")
struct DailyPlanPrereqTests {
    @Test("In-scope unreviewed prerequisite blocks its dependent the same day")
    func prereqBlocks() {
        // X = A1-02 (order 2) depends on Y = A1-05 (order 5, higher order, in scope, unreviewed).
        let cards = [
            card("A1-02", order: 2, related: ["A1-05"]),
            card("A1-05", order: 5),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 1), today: today)
        )
        // Despite A1-02 having lower order, it is blocked until A1-05 is introduced.
        #expect(newIDs(plan) == ["A1-05"])
    }

    @Test("Already-learned prerequisite does not block")
    func learnedPrereqDoesNotBlock() {
        let cards = [
            card("A1-02", order: 2, related: ["A1-01"]),
            card("A1-01", order: 1),
        ]
        let reviews = [review("A1-01", due: day(2026, 7, 1), status: .review)]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 1), today: today)
        )
        #expect(newIDs(plan) == ["A1-02"])
    }

    @Test("Out-of-scope prerequisite does not block")
    func outOfScopePrereqDoesNotBlock() {
        let cards = [
            card("A1-02", theme: "a1-1", order: 2, related: ["A1-09"]),
            card("A1-09", theme: "a1-9", order: 9),  // theme not selected → out of scope
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(
                cards: cards, reviews: [],
                settings: settings(target: .a1, themes: ["a1-1"], newPerDay: 1),
                today: today
            )
        )
        #expect(newIDs(plan) == ["A1-02"])
    }

    @Test("Dependent and prerequisite both admitted in dependency order when limit allows")
    func bothInDependencyOrder() {
        let cards = [
            card("A1-02", order: 2, related: ["A1-05"]),
            card("A1-05", order: 5),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 2), today: today)
        )
        #expect(newIDs(plan) == ["A1-05", "A1-02"])
    }

    @Test("A related cycle does not starve the planner")
    func cycleDoesNotStarve() {
        let cards = [
            card("A1-01", order: 1, related: ["A1-02"]),
            card("A1-02", order: 2, related: ["A1-01"]),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 2), today: today)
        )
        // Cycle broken by ascending order; both still get introduced.
        #expect(newIDs(plan) == ["A1-01", "A1-02"])
    }
}

// MARK: - 5. Reviews cap & overflow

@Suite("Daily plan — reviews cap")
struct DailyPlanCapTests {
    private func dueReviews(_ n: Int) -> (cards: [Card], reviews: [ReviewState]) {
        var cards: [Card] = []
        var reviews: [ReviewState] = []
        for i in 1...n {
            let id = String(format: "A1-%02d", i)
            cards.append(card(id, order: i))
            reviews.append(review(id, due: day(2026, 6, 1), status: .review))
        }
        return (cards, reviews)
    }

    @Test("Due cards under the cap are all admitted")
    func underCap() {
        let (cards, reviews) = dueReviews(20)
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today, maxReviewsPerDay: 50)
        )
        #expect(plan.counts.dueCount == 20)
    }

    @Test("Overflow due cards are deferred to exactly the cap")
    func overflowDeferred() {
        let (cards, reviews) = dueReviews(80)
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today, maxReviewsPerDay: 50)
        )
        #expect(plan.counts.dueCount == 50)
        #expect(dueIDs(plan).count == 50)
    }

    @Test("Default cap applies when none configured")
    func defaultCap() {
        let (cards, reviews) = dueReviews(80)
        // Request without an explicit cap uses DailyPlanner.defaultMaxReviewsPerDay.
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today)
        )
        #expect(plan.counts.dueCount == DailyPlanner.defaultMaxReviewsPerDay)
    }

    @Test("Most-overdue cards are admitted first")
    func mostOverdueFirst() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2), card("A1-03", order: 3)]
        let reviews = [
            review("A1-01", due: day(2026, 6, 23), status: .review),  // least overdue
            review("A1-02", due: day(2026, 6, 10), status: .review),  // most overdue
            review("A1-03", due: day(2026, 6, 20), status: .review),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today, maxReviewsPerDay: 2)
        )
        #expect(dueIDs(plan) == ["A1-02", "A1-03"])
    }

    @Test("Deferral does not mutate scheduling state")
    func deferralPure() {
        let (cards, reviews) = dueReviews(80)
        let snapshot = reviews
        _ = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today, maxReviewsPerDay: 50)
        )
        #expect(reviews == snapshot)
    }
}

// MARK: - 6. Assembly, ordering & edge cases

@Suite("Daily plan — assembly and edges")
struct DailyPlanAssemblyTests {
    @Test("Due cards precede new cards in the queue")
    func dueBeforeNew() {
        let cards = [
            card("A1-01", order: 1),  // due
            card("A1-02", order: 2),  // new
        ]
        let reviews = [review("A1-01", due: day(2026, 6, 1), status: .review)]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 5), today: today)
        )
        #expect(plan.queue.map(\.cardID) == ["A1-01", "A1-02"])
        #expect(plan.queue.map(\.kind) == [.due, .new])
    }

    @Test("Empty queue when nothing due and nothing new")
    func emptyQueue() {
        let cards = [card("A1-01", order: 1)]
        let reviews = [review("A1-01", due: day(2026, 6, 1), status: .review)]
        // newPerDay 0 → no new; only due card exists but reviewed already, and we
        // suppress reviews via a zero cap to reach a fully empty queue.
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 0), today: today, maxReviewsPerDay: 0)
        )
        #expect(plan.queue.isEmpty)
        #expect(plan.counts.dueCount == 0)
        #expect(plan.counts.newCount == 0)
        #expect(plan.counts.isEmpty)
    }

    @Test("Selection exhausted: due-only queue, zero new, scope-exhausted flag")
    func selectionExhausted() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2)]
        // Every in-scope card already has a review state; one is due.
        let reviews = [
            review("A1-01", due: day(2026, 6, 1), status: .review),
            review("A1-02", due: day(2026, 7, 1), status: .review),
        ]
        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 5), today: today)
        )
        #expect(dueIDs(plan) == ["A1-01"])
        #expect(plan.counts.newCount == 0)
        #expect(plan.counts.scopeExhausted)
        #expect(!plan.counts.isEmpty)
    }

    @Test("Determinism: shuffling inputs yields an identical queue and counts")
    func determinism() {
        let cards = [
            card("A1-01", order: 1), card("A1-02", order: 2),
            card("A1-03", order: 3), card("A1-04", order: 4, related: ["A1-03"]),
            card("A1-05", order: 5),
        ]
        let reviews = [
            review("A1-01", due: day(2026, 6, 20), status: .review),
            review("A1-02", due: day(2026, 6, 20), status: .learning),
        ]
        let base = DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 3), today: today)
        let expected = DailyPlanner.composePlan(base)

        var rng = SystemRandomNumberGenerator()
        for _ in 0..<25 {
            let shuffled = DailyPlanRequest(
                cards: cards.shuffled(using: &rng),
                reviews: reviews.shuffled(using: &rng),
                settings: base.settings,
                today: today
            )
            let plan = DailyPlanner.composePlan(shuffled)
            #expect(plan == expected)
        }
    }
}

// MARK: - 7. Count report & recomputation

@Suite("Daily plan — counts and recomputation")
struct DailyPlanCountsTests {
    private func sampleRequest(today: Date, newPerDay: Int = 3) -> DailyPlanRequest {
        let cards = [
            card("A1-01", order: 1), card("A1-02", order: 2),
            card("A1-03", order: 3), card("A1-04", order: 4),
        ]
        let reviews = [
            review("A1-01", due: day(2026, 6, 25), status: .review),  // due on/after the 25th
            review("A1-02", due: day(2026, 6, 20), status: .review),
        ]
        return DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: newPerDay), today: today)
    }

    @Test("Counts match the composed queue")
    func countsMatchQueue() {
        let plan = DailyPlanner.composePlan(sampleRequest(today: today))
        #expect(plan.counts.dueCount == dueIDs(plan).count)
        #expect(plan.counts.newCount == newIDs(plan).count)
    }

    @Test("Counts are obtainable without walking the full queue")
    func countsWithoutQueue() {
        let request = sampleRequest(today: today)
        let counts = DailyPlanner.composeCounts(request)
        #expect(counts == DailyPlanner.composePlan(request).counts)
    }

    @Test("Day rollover surfaces newly-due cards")
    func dayRollover() {
        // On the 24th, only A1-02 (due 6/20) is due. On the 25th, A1-01 also becomes due.
        let before = DailyPlanner.composePlan(sampleRequest(today: day(2026, 6, 24)))
        let after = DailyPlanner.composePlan(sampleRequest(today: day(2026, 6, 25)))
        #expect(before.counts.dueCount == 1)
        #expect(after.counts.dueCount == 2)
    }

    @Test("Settings change reflects new scope and limits")
    func settingsChange() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2), card("A1-03", order: 3)]
        let oneNew = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 1), today: today)
        )
        let threeNew = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 3), today: today)
        )
        #expect(oneNew.counts.newCount == 1)
        #expect(threeNew.counts.newCount == 3)
    }

    @Test("Grade-driven review change reflects updated membership")
    func gradeChange() {
        let cards = [card("A1-01", order: 1), card("A1-02", order: 2)]
        // Before grading: A1-01 has no state → eligible as new.
        let before = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: [], settings: settings(newPerDay: 5), today: today)
        )
        #expect(newIDs(before).contains("A1-01"))
        // After grading: A1-01 now has a (future-due) review state → no longer new, not due today.
        let reviews = [review("A1-01", due: day(2026, 7, 1), status: .review)]
        let after = DailyPlanner.composePlan(
            DailyPlanRequest(cards: cards, reviews: reviews, settings: settings(newPerDay: 5), today: today)
        )
        #expect(!newIDs(after).contains("A1-01"))
        #expect(!dueIDs(after).contains("A1-01"))
    }
}
