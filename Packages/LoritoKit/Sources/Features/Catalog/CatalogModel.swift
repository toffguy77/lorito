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
    private let store: UserDataStore
    private let catalog: ContentCatalog
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
}
