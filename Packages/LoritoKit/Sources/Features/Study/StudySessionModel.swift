import Foundation
import Observation
import Domain
import DesignSystem

/// Walks a snapshot study queue one card at a time, recall first: each card
/// opens on its front side (`isRevealed == false`) and can only be graded after
/// `reveal()`. Each grade applies the `srs-engine` update and writes a
/// `StudyLog` entry immediately (via `GradingService`), then advances — so a
/// mid-session exit leaves every graded card persisted and the next entry
/// resumes on the next ungraded card.
@MainActor
@Observable
public final class StudySessionModel {
    private let store: UserDataStore
    private let grading: GradingService
    private let analytics: AnalyticsRecording
    private let catalog: ContentCatalog
    /// The session's cards; a card graded Опять is appended once (relearn).
    private var queue: [String]
    /// Cards already re-queued this session (each at most once).
    private var relearned: Set<String> = []
    /// The session's "today", injected into previews and grading.
    let today: Date
    /// Desired retention for the caption preview (grading reads it itself).
    private let retention: Double

    public private(set) var index = 0
    /// Whether the current card's answer and grade buttons are shown.
    public private(set) var isRevealed = false
    /// Grades given so far this session, in queue order (drives the
    /// per-card outcome colors of the session progress bar).
    public private(set) var grades: [StudyGrade] = []
    private var sessionGrades: [SessionGrade] = []
    /// The session summary, computed once when the last card is graded.
    public private(set) var summary: SessionSummary?

    public init(store: UserDataStore, catalog: ContentCatalog, queue: [String], today: Date = Date(),
                analytics: AnalyticsRecording? = nil) {
        self.analytics = analytics ?? AnalyticsService.shared
        self.store = store
        self.grading = GradingService(store: store)
        self.catalog = catalog
        self.queue = queue
        self.today = today
        self.retention = (try? store.loadSettings().desiredRetention) ?? 0.9
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

    // MARK: Front side

    /// The card's `recall` Markdown, or a generic prompt built from its title.
    public var recallPrompt: String {
        guard let card = currentCard else { return "" }
        if let recall = card.recall?.trimmingCharacters(in: .whitespaces), !recall.isEmpty {
            return recall
        }
        return "Вспомните главное: «\(card.title)»"
    }

    /// For the fallback prompt only: the card's aliases as a hint line.
    public var recallHint: String? {
        guard let card = currentCard, card.recall == nil, !card.aliases.isEmpty else { return nil }
        let hint = card.aliases.filter { $0 != card.title }.joined(separator: " · ")
        return hint.isEmpty ? nil : hint
    }

    public func reveal() {
        guard !isComplete else { return }
        isRevealed = true
    }

    // MARK: Back side

    /// The current card's related cards — after reveal only (they would leak
    /// the answer on the front).
    public var visibleRelatedCards: [Card] {
        guard isRevealed, let card = currentCard else { return [] }
        return catalog.relatedCards(of: card)
    }

    /// A catalog model for opening a related card in the reader.
    func makeCatalogModel() -> CatalogModel { CatalogModel(store: store, catalog: catalog) }

    /// Interval preview per grade for the current card (read-only).
    public var captions: [StudyGrade: String] { preview(IntervalPreview.format(days:)) }

    /// VoiceOver form of the captions ("через 3 дня").
    public var spokenCaptions: [StudyGrade: String] { preview(IntervalPreview.spoken(days:)) }

    private func preview(_ format: (Int) -> String) -> [StudyGrade: String] {
        guard let id = currentCard?.id else { return [:] }
        let state = try? store.review(for: id)
        // A re-shown card's second grade doesn't reschedule it (first grade per
        // day), so every button truthfully shows the unchanged due date.
        if isRelearnPass, let state {
            let cal = Calendar.learningDay
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: today),
                                          to: cal.startOfDay(for: state.dueDate)).day ?? 0
            let caption = format(max(0, days))
            return Dictionary(uniqueKeysWithValues: StudyGrade.allCases.map { ($0, caption) })
        }
        let intervals = IntervalPreview.intervals(for: state, today: today, retention: retention)
        return Dictionary(uniqueKeysWithValues: intervals.map { ($0.key.studyGrade, format($0.value)) })
    }

    /// The current card is the re-shown copy of a card graded Опять earlier.
    private var isRelearnPass: Bool {
        guard index < queue.count else { return false }
        return relearned.contains(queue[index]) && queue[..<index].contains(queue[index])
    }

    /// Apply a grade to the current (revealed) card and advance. No-op on the
    /// front side.
    public func grade(_ grade: StudyGrade) {
        guard index < queue.count, isRevealed else { return }
        let cardID = queue[index]
        _ = try? grading.grade(cardID: cardID, grade: grade.domain, today: today)
        grades.append(grade)
        sessionGrades.append(SessionGrade(cardID: cardID, grade: grade.domain))
        analytics.record(.itemGraded(kind: ItemKind.parse(cardID), grade: grade.domain, revealed: true))
        // In-session relearn: an Опять card comes back once at the end.
        if grade == .again, !relearned.contains(cardID) {
            relearned.insert(cardID)
            queue.append(cardID)
        }
        index += 1
        isRevealed = false
        if isComplete {
            let summary = makeSummary()
            self.summary = summary
            analytics.record(.sessionCompleted(items: summary.studied, firstTryPercent: summary.firstTryPercent))
        }
    }

    // MARK: Completion

    private func makeSummary() -> SessionSummary {
        let events = (try? store.allEvents()) ?? []
        let stats = StatsCalculator.compute(events: events, today: today)
        let cards = Dictionary(uniqueKeysWithValues: sessionGrades.compactMap { g in
            catalog.card(id: g.cardID).map { (g.cardID, $0) }
        }.uniqued())
        return SessionSummary.make(grades: sessionGrades, cardsByID: cards, stats: stats)
    }

    /// Titles of the summary's themes to revisit.
    public var revisitThemeTitles: [String] {
        (summary?.revisitThemeIDs ?? []).map { catalog.theme(id: $0)?.title ?? $0 }
    }
}

private extension Array where Element == (String, Card) {
    /// Drop repeated keys (a card graded twice) so the dictionary init is safe.
    func uniqued() -> [(String, Card)] {
        var seen = Set<String>()
        return filter { seen.insert($0.0).inserted }
    }
}
