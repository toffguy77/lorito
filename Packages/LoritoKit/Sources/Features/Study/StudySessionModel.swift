import Foundation
import Observation
import Domain
import DesignSystem

/// Walks a snapshot study queue one card at a time. Each grade applies the
/// `srs-engine` update and writes a `StudyLog` entry immediately (via
/// `GradingService`), then advances — so a mid-session exit leaves every graded
/// card persisted and the next entry resumes on the next ungraded card.
@MainActor
@Observable
public final class StudySessionModel {
    private let grading: GradingService
    private let catalog: ContentCatalog
    private let queue: [String]

    public private(set) var index = 0

    public init(store: UserDataStore, catalog: ContentCatalog, queue: [String]) {
        self.grading = GradingService(store: store)
        self.catalog = catalog
        self.queue = queue
    }

    public var currentCard: Card? {
        guard index < queue.count else { return nil }
        return catalog.card(id: queue[index])
    }

    /// True once the last card has been graded.
    public var isComplete: Bool { index >= queue.count }

    /// "3 / 8" position label.
    public var positionText: String {
        "\(min(index + 1, queue.count)) / \(queue.count)"
    }

    /// Apply a grade to the current card and advance.
    public func grade(_ grade: StudyGrade) {
        guard index < queue.count else { return }
        _ = try? grading.grade(cardID: queue[index], grade: grade.domain, today: Date())
        index += 1
    }
}
