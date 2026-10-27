import Foundation
import Observation
import Domain
import Content

/// Grammar Lens: analyses Spanish text on the device and links constructions to
/// cards. The text lives only in memory — nothing is stored unless the user adds
/// a card to review.
@MainActor
@Observable
public final class LensModel: Identifiable {
    public let id = UUID()

    /// A highlighted construction.
    public struct Highlight: Identifiable, Equatable {
        public let id: Int
        public let text: String
        public let range: Range<String.Index>
        public let ruleID: String
        public let title: String
        public let cards: [Card]
    }

    public enum CardStatus: Equatable {
        case new
        case requested
        /// Has review state; due in `days` learning days (0 = today or overdue).
        case scheduled(days: Int)
    }

    /// Nil in the Action extension (results only; adding to review happens in the app).
    private let store: UserDataStore?
    private let catalog: ContentCatalog
    private let lens: LensCatalog
    private let analytics: AnalyticsRecording
    private let now: () -> Date
    public let source: LensSource

    public var text: String = ""
    public private(set) var highlights: [Highlight] = []
    public private(set) var didAnalyze = false
    /// Bumped on requests so views re-read statuses.
    public private(set) var statusVersion = 0

    public init(store: UserDataStore?, catalog: ContentCatalog, lens: LensCatalog, source: LensSource,
                text: String = "", analytics: AnalyticsRecording? = nil, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.lens = lens
        self.source = source
        self.text = text
        self.analytics = analytics ?? AnalyticsService.shared
        self.now = now
        self.analytics.record(.lensOpened(source: source))
    }

    public var coveredTopics: [String] { lens.coveredTopics }

    /// The bundled rules (nil when the bundle has no lens.json).
    public nonisolated static func bundledCatalog() -> LensCatalog? { try? ContentLoader.loadLens() }

    public func analyze() {
        let tokens = LensTokenizer.tokens(text, lemmas: lens.lemmas)
        highlights = lens.match(tokens).enumerated().compactMap { i, m in
            guard let rule = lens.rule(m.rule),
                  let lower = tokens[m.start].range?.lowerBound, let upper = tokens[m.end].range?.upperBound else { return nil }
            return Highlight(id: i, text: String(text[lower..<upper]), range: lower..<upper, ruleID: rule.id,
                             title: rule.titleRu, cards: rule.cards.compactMap(catalog.card(id:)))
        }
        didAnalyze = true
        analytics.record(.lensAnalyzed(source: source, matches: LensMatchBucket(highlights.count)))
    }

    public func status(for cardID: String) -> CardStatus {
        _ = statusVersion
        guard let store else { return .new }
        if let review = try? store.review(for: cardID) {
            let today = Calendar.learningDay.startOfDay(for: now())
            let due = Calendar.learningDay.startOfDay(for: review.dueDate)
            let days = Calendar.learningDay.dateComponents([.day], from: today, to: due).day ?? 0
            return .scheduled(days: max(0, days))
        }
        if ((try? store.allRequestedItems()) ?? []).contains(where: { $0.itemID == cardID }) { return .requested }
        return .new
    }

    /// «Добавить в повторение»: only for cards without review state (their schedule is never moved).
    public func request(_ cardID: String) {
        guard let store, status(for: cardID) == .new else { return }
        try? store.requestItem(cardID, at: now())
        statusVersion += 1
        analytics.record(.lensCardRequested)
    }

    public nonisolated static func statusText(_ status: CardStatus) -> String {
        switch status {
        case .new: return "Добавить в повторение"
        case .requested: return "Добавлено — появится в плане дня"
        case .scheduled(let days):
            return days == 0 ? "Уже в повторении — сегодня" : "Уже в повторении — через \(RussianPlural.days(days))"
        }
    }
}
