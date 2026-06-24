import Foundation

// The pure, deterministic daily-plan composer. Given a content snapshot, the
// current per-card `ReviewState`s, `UserSettings`, and an injected "today", it
// produces one bounded, ordered study queue plus a new-vs-due count report.
//
// It performs no I/O and reads no global clock (the SRS `DueSelection` calendar
// it relies on compares against the injected `today`). Identical input always
// yields identical output. Consumed by `study-flow` (walks the queue) and
// `reminders` (reads the counts).

/// Whether a queue entry is a due review or a freshly introduced new card.
public enum PlanEntryKind: String, Sendable, Hashable, Codable {
    case due
    case new
}

/// One position in the day's ordered study queue.
public struct PlanEntry: Sendable, Hashable, Codable {
    public let cardID: String
    public let kind: PlanEntryKind

    public init(cardID: String, kind: PlanEntryKind) {
        self.cardID = cardID
        self.kind = kind
    }
}

/// The new-vs-due breakdown for the Today screen and reminders. Derivable
/// without walking the full queue (see `DailyPlanner.composeCounts`).
public struct DailyPlanCounts: Sendable, Hashable, Codable {
    /// Number of due (`review`/`learning`) cards admitted to today's queue.
    public let dueCount: Int
    /// Number of brand-new cards introduced into today's queue.
    public let newCount: Int
    /// True when the user's selection holds no further unintroduced new cards.
    public let scopeExhausted: Bool

    public init(dueCount: Int, newCount: Int, scopeExhausted: Bool) {
        self.dueCount = dueCount
        self.newCount = newCount
        self.scopeExhausted = scopeExhausted
    }

    /// True when nothing is due and nothing new was introduced.
    public var isEmpty: Bool { dueCount == 0 && newCount == 0 }
}

/// The composed plan: an ordered queue (due cards first, then new) and its counts.
public struct DailyPlan: Sendable, Hashable, Codable {
    public let queue: [PlanEntry]
    public let counts: DailyPlanCounts

    public init(queue: [PlanEntry], counts: DailyPlanCounts) {
        self.queue = queue
        self.counts = counts
    }
}

/// The bundle of inputs the planner reads. A value type so recomputation is
/// simply re-invoking the planner with an updated request.
public struct DailyPlanRequest: Sendable {
    /// Read-only content snapshot (each `Card` exposes `id`/`level`/`themeID`/`order`/`related`).
    public var cards: [Card]
    /// Current per-card scheduling states (as produced by `srs-engine`).
    public var reviews: [ReviewState]
    /// User-chosen scope and limits.
    public var settings: UserSettings
    /// The injected "today"; all due comparisons use this, never the system clock.
    public var today: Date
    /// Maximum due cards admitted to a single day; overflow is deferred.
    public var maxReviewsPerDay: Int

    public init(
        cards: [Card],
        reviews: [ReviewState],
        settings: UserSettings,
        today: Date,
        maxReviewsPerDay: Int = DailyPlanner.defaultMaxReviewsPerDay
    ) {
        self.cards = cards
        self.reviews = reviews
        self.settings = settings
        self.today = today
        self.maxReviewsPerDay = maxReviewsPerDay
    }
}

public enum DailyPlanner {
    /// Sensible default cap on due cards per day, applied when callers do not
    /// configure one. Generous enough not to interfere with normal use.
    public static let defaultMaxReviewsPerDay = 50

    /// Compose today's ordered study queue and its count report.
    public static func composePlan(_ request: DailyPlanRequest) -> DailyPlan {
        let selection = select(request)
        let queue =
            selection.dueIDs.map { PlanEntry(cardID: $0, kind: .due) }
            + selection.newIDs.map { PlanEntry(cardID: $0, kind: .new) }
        return DailyPlan(queue: queue, counts: selection.counts)
    }

    /// Compute just the count report, without materializing the full queue.
    /// Used by `reminders` and the Today screen. Runs the same selection pass
    /// so the numbers always match `composePlan`'s queue.
    public static func composeCounts(_ request: DailyPlanRequest) -> DailyPlanCounts {
        select(request).counts
    }

    // MARK: - Shared selection pass

    private struct Selection {
        let dueIDs: [String]
        let newIDs: [String]
        let counts: DailyPlanCounts
    }

    private static func select(_ request: DailyPlanRequest) -> Selection {
        let reviewsByID = Dictionary(
            request.reviews.map { ($0.cardID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let dueIDs = selectDue(request: request, reviewsByID: reviewsByID)
        let (newIDs, scopeExhausted) = selectNew(request: request, reviewsByID: reviewsByID)

        let counts = DailyPlanCounts(
            dueCount: dueIDs.count,
            newCount: newIDs.count,
            scopeExhausted: scopeExhausted
        )
        return Selection(dueIDs: dueIDs, newIDs: newIDs, counts: counts)
    }

    // MARK: - Due selection

    /// Due `review`/`learning` cards (`suspended`/no-state excluded), ordered
    /// `dueDate` ascending then `id` ascending — so the most overdue come first
    /// — then capped at `maxReviewsPerDay`; overflow is omitted (deferred) and
    /// no scheduling state is mutated.
    private static func selectDue(
        request: DailyPlanRequest,
        reviewsByID: [String: ReviewState]
    ) -> [String] {
        let due = request.reviews
            .filter { DueSelection.isDue($0, on: request.today) }
            .sorted { lhs, rhs in
                if lhs.dueDate != rhs.dueDate { return lhs.dueDate < rhs.dueDate }
                return lhs.cardID < rhs.cardID
            }
        let cap = max(0, request.maxReviewsPerDay)
        return due.prefix(cap).map(\.cardID)
    }

    // MARK: - New selection

    /// Eligible new cards, introduced in ascending `order` (then `id`) while
    /// respecting `related` prerequisites and the `dailyNewCardCount` limit.
    /// Returns the introduced ids in queue order plus whether the new-card
    /// scope is exhausted (no eligible new cards remain in the selection).
    private static func selectNew(
        request: DailyPlanRequest,
        reviewsByID: [String: ReviewState]
    ) -> (ids: [String], scopeExhausted: Bool) {
        let settings = request.settings

        // In-scope = included level (target plus all lower) and selected theme.
        // An empty `selectedThemeIDs` means "all themes in scope" (foundation contract).
        let includedLevels = Set(settings.targetLevel?.included ?? [])
        let selectedThemes = Set(settings.selectedThemeIDs)
        func inScope(_ card: Card) -> Bool {
            guard includedLevels.contains(card.level) else { return false }
            return selectedThemes.isEmpty || selectedThemes.contains(card.themeID)
        }

        let inScopeIDs = Set(request.cards.filter(inScope).map(\.id))

        // Eligible new = in scope and no prior review state, ordered (order, id).
        let eligible = request.cards
            .filter { inScope($0) && reviewsByID[$0.id] == nil }
            .sorted { lhs, rhs in
                if lhs.order != rhs.order { return lhs.order < rhs.order }
                return lhs.id < rhs.id
            }
        let scopeExhausted = eligible.isEmpty

        let limit = max(0, settings.dailyNewCardCount)
        guard limit > 0, !eligible.isEmpty else {
            return ([], scopeExhausted)
        }

        // Prerequisites = `related` ∩ selection. Satisfied when the prerequisite
        // already has a review state (introduced on a prior day) or is introduced
        // earlier in this same plan.
        var prereqs: [String: [String]] = [:]
        for card in eligible {
            prereqs[card.id] = card.related.filter { inScopeIDs.contains($0) }
        }

        // Greedy topological introduction under the daily limit. `introduced`
        // starts with every card that already has a review state.
        var introduced = Set(reviewsByID.keys)
        var introducedToday: [String] = []
        var remaining = eligible

        while introducedToday.count < limit, !remaining.isEmpty {
            let available = remaining.first { card in
                (prereqs[card.id] ?? []).allSatisfy { introduced.contains($0) }
            }
            // Defensive cycle break: if no card's prerequisites are satisfied
            // (a `related` cycle within the selection), take the lowest (order, id)
            // remaining card so introduction always makes progress.
            let pick = available ?? remaining[0]

            introducedToday.append(pick.id)
            introduced.insert(pick.id)
            remaining.removeAll { $0.id == pick.id }
        }

        return (introducedToday, scopeExhausted)
    }
}
