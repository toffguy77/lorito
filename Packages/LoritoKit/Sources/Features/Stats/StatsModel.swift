import Foundation
import Observation
import Domain

/// Loads the study log and reviews and computes everything the progress
/// screen shows: streak and counts, the 12-week activity series with its
/// intensity buckets, and long-term memory per included level.
@MainActor
@Observable
public final class StatsModel {
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let fixedToday: Date?

    public private(set) var stats: StudyStats = .empty
    /// The last 84 days, oldest first.
    public private(set) var activity: [DailyActivity] = []
    /// Intensity bucket (0–3) per `activity` entry.
    public private(set) var buckets: [Int] = []
    /// Grade events within the activity window.
    public private(set) var windowTotal = 0
    /// Long-term memory for each included level (lowest first).
    public private(set) var memory: [LevelMemory] = []

    /// `today` is injectable for tests; nil means the current date at refresh.
    public init(store: UserDataStore, catalog: ContentCatalog, today: Date? = nil) {
        self.store = store
        self.catalog = catalog
        self.fixedToday = today
        refresh()
    }

    public var hasHistory: Bool { stats.studiedAllTime > 0 }

    public func refresh() {
        let today = fixedToday ?? Date()
        let events = (try? store.allEvents()) ?? []
        let reviews = (try? store.allReviews()) ?? []
        let settings = (try? store.loadSettings()) ?? .default

        stats = StatsCalculator.compute(events: events, today: today)
        activity = StatsCalculator.dailyActivity(events: events, days: StatsConstants.heatmapDays, today: today)
        buckets = StatsCalculator.buckets(for: activity.map(\.count))
        windowTotal = activity.reduce(0) { $0 + $1.count }
        let levels = settings.targetLevel.map(SelectionScope.includedLevels(for:)) ?? []
        memory = StatsCalculator.longTermMemory(reviews: reviews, catalog: catalog, levels: levels)
    }
}
