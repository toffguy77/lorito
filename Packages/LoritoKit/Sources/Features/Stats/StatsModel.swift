import Foundation
import Observation
import Domain

/// Loads the study log and computes `StudyStats` for the progress screen.
@MainActor
@Observable
public final class StatsModel {
    private let store: UserDataStore
    public private(set) var stats: StudyStats = .empty

    public init(store: UserDataStore) {
        self.store = store
        refresh()
    }

    public var hasHistory: Bool { stats.studiedAllTime > 0 }

    public func refresh() {
        let events = (try? store.allEvents()) ?? []
        stats = StatsCalculator.compute(events: events, today: Date())
    }
}
