import Foundation
import Domain

/// Today's conjugation items (due ≤ 20 + new within the quota and budget).
enum ConjugationToday {
    static func plan(store: UserDataStore, catalog: ContentCatalog, today: Date = Date(),
                     calendar: Calendar = .learningDay) -> ConjugationPlan? {
        guard let conj = catalog.conjugation else { return nil }
        let settings = (try? store.loadSettings()) ?? .default
        let reviews = (try? store.allReviews()) ?? []
        let events = (try? store.allEvents()) ?? []
        let unlocked = ConjugationUnlock.unlockedTenses(conj, cards: catalog.cards, reviews: reviews, settings: settings)
        let ledger = IntroductionLedger(events: events, day: today, calendar: calendar)
        let plan = ConjugationPlanner.plan(conj, unlocked: unlocked, reviews: reviews, events: events,
                                           quota: settings.dailyConjugationCount, cardQuota: settings.dailyNewCardCount,
                                           introducedToday: ledger.countsByKind, today: today, calendar: calendar)
        // Items already graded today are done for the day.
        let gradedToday = Set(events.filter { $0.grade != nil && calendar.isDate($0.date, inSameDayAs: today) }.map(\.cardID))
        let due = plan.due.filter { !gradedToday.contains($0) }
        let new = plan.new.filter { !gradedToday.contains($0) }
        return ConjugationPlan(due: due, new: new)
    }

    /// The reader's «Тренировать спряжения» for a tense card: today's planned
    /// items of that tense, then already-studied ones (practice), up to 5.
    static func readerItems(tenseCard cardID: String, store: UserDataStore, catalog: ContentCatalog) -> [String] {
        guard let conj = catalog.conjugation,
              let tense = conj.tenses.first(where: { $0.card == cardID }) else { return [] }
        let suffix = ":\(tense.id)"
        let planned = (plan(store: store, catalog: catalog)?.all ?? []).filter { $0.hasSuffix(suffix) }
        let studied = ((try? store.allReviews()) ?? []).map(\.cardID).filter { $0.hasPrefix("conj:") && $0.hasSuffix(suffix) }.sorted()
        var out: [String] = []
        for id in planned + studied where !out.contains(id) { out.append(id) }
        return Array(out.prefix(5))
    }
}
