import Foundation
import Observation
import Domain

/// Drives the Today screen. Reads the day's queue and counts from `daily-plan`
/// (it does not compute the queue itself), subtracts cards already graded today
/// so a returning user resumes where they left off, and derives the day-progress
/// numbers and the empty/all-done states.
@MainActor
@Observable
public final class TodayModel {
    private let store: UserDataStore
    private let catalog: ContentCatalog

    /// Cards still to study today, in queue order.
    public private(set) var remaining: [PlanEntry] = []
    public private(set) var dueRemaining = 0
    public private(set) var newRemaining = 0
    /// Cards graded so far today (drives the progress indicator).
    public private(set) var studiedCount = 0

    public init(store: UserDataStore, catalog: ContentCatalog) {
        self.store = store
        self.catalog = catalog
        refresh()
    }

    /// Total cards for the day = studied + remaining (stable as good/easy grades
    /// drop cards out of the recomputed plan).
    public var totalCount: Int { studiedCount + remaining.count }

    public var hasWork: Bool { !remaining.isEmpty }
    /// Distinct from `isEmpty`: work existed today and is now finished.
    public var isAllDone: Bool { remaining.isEmpty && studiedCount > 0 }
    /// Nothing was due and nothing new is available today.
    public var isEmpty: Bool { remaining.isEmpty && studiedCount == 0 }

    /// Localized "N на повторение + M новых".
    public var summary: String {
        "\(dueRemaining) на повторение + \(newRemaining) новых"
    }

    /// The ordered card ids to study now (snapshot for a session).
    public func sessionQueue() -> [String] { remaining.map(\.cardID) }

    /// Recompute from persistence — call on appearance and after a session.
    public func refresh() {
        let settings = (try? store.loadSettings()) ?? .default
        let reviews = (try? store.allReviews()) ?? []
        let events = (try? store.allEvents()) ?? []
        let today = Date()

        let plan = DailyPlanner.composePlan(
            DailyPlanRequest(cards: catalog.cards, reviews: reviews, settings: settings, today: today)
        )
        let gradedToday = Set(
            events.filter { $0.grade != nil && StudyDay.isSameDay($0.date, today) }.map(\.cardID)
        )
        remaining = plan.queue.filter { !gradedToday.contains($0.cardID) }
        dueRemaining = remaining.filter { $0.kind == .due }.count
        newRemaining = remaining.filter { $0.kind == .new }.count
        studiedCount = gradedToday.count
    }
}
