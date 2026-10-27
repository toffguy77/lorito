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
    /// Grades given so far this session, in queue order (drives the
    /// per-card outcome colors of the session progress bar).
    public private(set) var grades: [StudyGrade] = []

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

    public var totalCount: Int { queue.count }

    /// One progress segment per queued card: graded cards by outcome, then
    /// the current card, then pending ones.
    public var segments: [SessionSegment] {
        (0..<queue.count).map { i in
            if i < grades.count { return grades[i] == .again ? .missed : .passed }
            return i == index ? .current : .pending
        }
    }

    /// "3 / 8" position label.
    public var positionText: String {
        "\(min(index + 1, queue.count)) / \(queue.count)"
    }

    /// Apply a grade to the current card and advance.
    public func grade(_ grade: StudyGrade) {
        guard index < queue.count else { return }
        _ = try? grading.grade(cardID: queue[index], grade: grade.domain, today: Date())
        grades.append(grade)
        index += 1
    }
}
