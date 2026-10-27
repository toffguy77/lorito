import Foundation
import Observation
import Domain

/// The status shown on a catalog card row, derived from its `CardReview`.
public enum CatalogCardStatus: String, Sendable {
    case new
    case learning
    case review
    case due
    case suspended

    public var title: String {
        switch self {
        case .new: return "новая"
        case .learning: return "изучается"
        case .review: return "повтор"
        case .due: return "пора"
        case .suspended: return "отложена"
        }
    }
}

/// Backs the catalog: browses the bundled levels → themes → cards, derives each
/// card's status from its `CardReview`, and suspends / unsuspends a card by
/// setting `CardReview.status`.
@MainActor
@Observable
public final class CatalogModel {
    let store: UserDataStore
    let catalog: ContentCatalog
    private var reviewsByID: [String: ReviewState] = [:]

    public init(store: UserDataStore, catalog: ContentCatalog) {
        self.store = store
        self.catalog = catalog
        refresh()
    }

    public func refresh() {
        let reviews = (try? store.allReviews()) ?? []
        reviewsByID = Dictionary(reviews.map { ($0.cardID, $0) }, uniquingKeysWith: { first, _ in first })
    }

    // MARK: Browsing (bundle order preserved)

    public var levels: [CEFRLevel] { catalog.levels }
    public func themes(in level: CEFRLevel) -> [Theme] { catalog.themes(in: level) }
    public func cards(in theme: Theme) -> [Card] { catalog.cards(themeID: theme.id) }
    public func theme(id: String) -> Theme? { catalog.theme(id: id) }

    // MARK: Progress

    /// Cards of a theme the user has started (any status but `new`) of its total.
    public func progress(in theme: Theme) -> (started: Int, total: Int) {
        let cards = cards(in: theme)
        return (cards.filter { status(for: $0.id) != .new }.count, cards.count)
    }

    /// Started cards across the whole catalog, of all cards.
    public var overallProgress: (started: Int, total: Int) {
        let all = levels.flatMap(themes(in:)).flatMap(cards(in:))
        return (all.filter { status(for: $0.id) != .new }.count, all.count)
    }

    /// The theme to continue in a level: the first one not fully started.
    public func currentTheme(in level: CEFRLevel) -> Theme? {
        themes(in: level).first { let p = progress(in: $0); return p.started < p.total }
    }

    // MARK: Practice

    /// Exercises drilling a given card.
    public func exercises(forCard cardID: String) -> [Exercise] {
        catalog.exercises(forCard: cardID)
    }

    /// A fresh practice session for a card's exercises (nil when it has none).
    /// Listening types need a Spanish voice; `speak` uses on-device recognition when available.
    public func makeExerciseSession(forCard cardID: String, hasSpanishVoice: Bool = true) -> ExerciseSessionModel? {
        var exercises = catalog.exercises(forCard: cardID)
        // UI testing only: `-lorito-practice-types listen-choose,dictation` limits the session.
        let args = CommandLine.arguments
        if args.contains("-lorito-ui-testing"), let i = args.firstIndex(of: "-lorito-practice-types"), i + 1 < args.count {
            let types = Set(args[i + 1].split(separator: ",").map(String.init))
            exercises = exercises.filter { types.contains($0.kind.typeName) }
        }
        guard !exercises.isEmpty else { return nil }
        let session = ExerciseSessionModel(store: store, exercises: exercises, recognizer: SystemSpeechRecognizer(),
                                           hasSpanishVoice: hasSpanishVoice)
        return session.count > 0 ? session : nil
    }

    // MARK: Status

    public func status(for cardID: String) -> CatalogCardStatus {
        guard let review = reviewsByID[cardID] else { return .new }
        switch review.status {
        case .new: return .new
        case .suspended: return .suspended
        case .learning: return .learning
        case .review:
            return DueSelection.isDue(review, on: Date()) ? .due : .review
        }
    }

    public func isSuspended(_ cardID: String) -> Bool {
        reviewsByID[cardID]?.status == .suspended
    }

    /// Suspend or unsuspend a card, creating a `CardReview` if absent. On
    /// unsuspend the status returns to `review` if the card was studied before,
    /// otherwise `new`.
    public func toggleSuspended(_ cardID: String) {
        var review = reviewsByID[cardID] ?? ReviewState(cardID: cardID)
        if review.status == .suspended {
            review.status = review.repetitions > 0 ? .review : .new
        } else {
            review.status = .suspended
        }
        try? store.upsertReview(review)
        reviewsByID[cardID] = review
    }

    /// «Тренировать спряжения» on a tense card (conjugation-trainer); nil when nothing to drill.
    func makeConjugationDrill(forCard cardID: String) -> ConjugationDrillModel? {
        guard let conj = catalog.conjugation else { return nil }
        let items = ConjugationToday.readerItems(tenseCard: cardID, store: store, catalog: catalog)
        return items.isEmpty ? nil : ConjugationDrillModel(store: store, catalog: conj, itemIDs: items)
    }
}
