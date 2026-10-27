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
    private let catalog: ContentCatalog
    private let queue: [String]
    /// The session's "today", injected into previews and grading.
    let today: Date

    public private(set) var index = 0
    /// Whether the current card's answer and grade buttons are shown.
    public private(set) var isRevealed = false
    /// Grades given so far this session, in queue order (drives the
    /// per-card outcome colors of the session progress bar).
    public private(set) var grades: [StudyGrade] = []
    private var sessionGrades: [SessionGrade] = []
    /// The session summary, computed once when the last card is graded.
    public private(set) var summary: SessionSummary?

    public init(store: UserDataStore, catalog: ContentCatalog, queue: [String], today: Date = Date()) {
        self.store = store
        self.grading = GradingService(store: store)
        self.catalog = catalog
        self.queue = queue
        self.today = today
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
    public var captions: [StudyGrade: String] {
        preview { IntervalPreview.captions(for: $0, today: today) }
    }

    /// VoiceOver form of the captions ("через 3 дня").
    public var spokenCaptions: [StudyGrade: String] {
        preview { IntervalPreview.spokenCaptions(for: $0, today: today) }
    }

    private func preview(_ make: (ReviewState?) -> [Grade: String]) -> [StudyGrade: String] {
        guard let id = currentCard?.id else { return [:] }
        let state = try? store.review(for: id)
        return Dictionary(uniqueKeysWithValues: make(state).map { ($0.key.studyGrade, $0.value) })
    }

    /// Apply a grade to the current (revealed) card and advance. No-op on the
    /// front side.
    public func grade(_ grade: StudyGrade) {
        guard index < queue.count, isRevealed else { return }
        _ = try? grading.grade(cardID: queue[index], grade: grade.domain, today: today)
        grades.append(grade)
        sessionGrades.append(SessionGrade(cardID: queue[index], grade: grade.domain))
        index += 1
        isRevealed = false
        if isComplete { summary = makeSummary() }
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
