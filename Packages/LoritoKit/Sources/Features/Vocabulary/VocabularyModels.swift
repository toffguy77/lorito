import Foundation
import Observation
import Domain

/// Words: personal deck management, deck selection and today's word plan.
@MainActor
@Observable
public final class VocabularyModel: Identifiable {
    public let id = UUID()
    let store: UserDataStore
    let catalog: ContentCatalog
    private let now: () -> Date
    public private(set) var settings: UserSettings
    public private(set) var personalWords: [PersonalWord] = []

    public enum SaveOutcome: Equatable { case added(String), alreadySaved(String), unknown(String) }

    public init(store: UserDataStore, catalog: ContentCatalog, today: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.now = today
        self.settings = (try? store.loadSettings()) ?? .default
        refresh()
    }

    public func refresh() {
        settings = (try? store.loadSettings()) ?? .default
        personalWords = ((try? store.allPersonalWords()) ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    public var decks: [Deck] { catalog.vocabulary?.decks ?? [] }
    public var isEnabled: Bool { settings.dailyNewWordCount > 0 }

    /// «В мои слова» on a Spanish span: a bundled word joins the personal deck;
    /// an unknown one needs a translation first (`saveUnknown`).
    public func save(_ text: String) -> SaveOutcome {
        guard let word = catalog.vocabulary?.lookup(text) else { return .unknown(text) }
        if settings.personalWordIDs.contains(word.id) { return .alreadySaved(word.display) }
        update { $0.personalWordIDs.append(word.id) }
        return .added(word.display)
    }

    public func saveUnknown(_ es: String, ru: String?, sourceCardID: String? = nil) {
        let w = PersonalWord(es: es.trimmingCharacters(in: .whitespacesAndNewlines),
                             ru: ru?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty, sourceCardID: sourceCardID,
                             createdAt: now())
        try? store.savePersonalWord(w)
        update { $0.personalWordIDs.append(w.deckID) }
        refresh()
    }

    /// Personal deck entries in display form (bundled + own words).
    public var personalEntries: [(id: String, es: String, ru: String)] {
        settings.personalWordIDs.compactMap { pid in
            if let w = catalog.vocabulary?.word(pid) { return (pid, w.display, w.ru) }
            if let p = personalWords.first(where: { $0.deckID == pid }) { return (pid, p.es, p.ru ?? "") }
            return nil
        }
    }

    /// Removes it from the personal deck (own words: the record too) and its review state; events stay.
    public func deletePersonal(_ pid: String) {
        update { $0.personalWordIDs.removeAll { $0 == pid } }
        if let p = personalWords.first(where: { $0.deckID == pid }) { try? store.deletePersonalWord(p.id) }
        if pid.hasPrefix("p-") { try? store.deleteReview(for: Word.itemID(pid)) }
        refresh()
    }

    public func setEnabled(_ on: Bool) {
        update { $0.dailyNewWordCount = on ? UserSettings.wordsDefaultWhenEnabled : 0 }
    }

    public var quota: Int {
        get { settings.dailyNewWordCount }
        set { update { $0.dailyNewWordCount = min(max(newValue, 0), 20) } }
    }

    public func isSelected(_ deck: Deck) -> Bool { VocabularySelection.selected(decks, settings: settings).contains(deck.id) }

    public func toggle(_ deck: Deck) {
        update { s in s.selectedDeckIDs = VocabularySelection.toggled(deck.id, decks: decks, settings: s) }
    }

    public func progress(_ deck: Deck) -> (started: Int, total: Int) {
        let known = Set(((try? store.allReviews()) ?? []).map(\.cardID))
        return (deck.words.filter { known.contains(Word.itemID($0.id)) }.count, deck.words.count)
    }

    /// Today's word items (due + new within the quota and the budget).
    public func todayItems(today: Date? = nil) -> [String] {
        guard let vocab = catalog.vocabulary else { return [] }
        let day = today ?? now()
        let events = (try? store.allEvents()) ?? []
        let personal = settings.personalWordIDs.map(Word.itemID)
        let plan = VocabularyPlanner.plan(vocab, settings: settings, personal: personal, reviews: (try? store.allReviews()) ?? [],
                                          introducedToday: IntroductionLedger(events: events, day: day).countsByKind, today: day)
        let gradedToday = Set(events.filter { $0.grade != nil && Calendar.learningDay.isDate($0.date, inSameDayAs: day) }.map(\.cardID))
        return plan.filter { !gradedToday.contains($0) }
    }

    func word(forItem itemID: String) -> Word? {
        let id = String(itemID.dropFirst("word:".count))
        if let w = catalog.vocabulary?.word(id) { return w }
        return personalWords.first { $0.deckID == id }?.asWord
    }

    private func update(_ change: (inout UserSettings) -> Void) {
        var s = (try? store.loadSettings()) ?? .default
        change(&s)
        try? store.saveSettings(s)
        settings = s
    }
}

/// A word session: recognition (word + audio → reveal → self-grade) until the
/// last two memory-updating reviews passed, then production (Russian → typed
/// Spanish with article, accent-aware). Grades go through `GradingService`.
@MainActor
@Observable
public final class WordSessionModel: Identifiable {
    public let id = UUID()
    private let store: UserDataStore
    private let grading: GradingService
    private let now: () -> Date
    public let items: [(itemID: String, word: Word)]
    public private(set) var index = 0
    public private(set) var isRevealed = false
    public var typed = ""
    public private(set) var check: VocabularyCheck?
    public private(set) var mode: VocabularyMode = .recognition
    /// The learner's variant: shown form, audio and expected answer.
    public let variant: SpanishVariant

    init(store: UserDataStore, items: [(String, Word)], now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.variant = ((try? store.loadSettings()) ?? .default).spanishVariant
        self.grading = GradingService(store: store)
        self.items = items.map { (itemID: $0.0, word: $0.1) }
        self.now = now
        updateMode()
    }

    public var current: (itemID: String, word: Word)? { index < items.count ? items[index] : nil }
    /// The current word as the learner's variant says it.
    public var shown: Word? { current?.word.resolved(for: variant) }
    /// Other regions' forms, listed once the answer is revealed or checked.
    public var otherForms: [VariantForm] {
        guard let c = current, isRevealed || check != nil else { return [] }
        return c.word.otherForms(for: variant)
    }
    public var isComplete: Bool { index >= items.count }

    public func reveal() { isRevealed = true }

    /// Recognition: self-grade after reveal.
    public func selfGrade(_ grade: Grade) {
        guard let c = current, isRevealed, mode == .recognition else { return }
        _ = try? grading.grade(cardID: c.itemID, grade: grade, today: now())
        advance()
    }

    /// Production: check the typed answer and grade.
    public func submit() {
        guard let c = current, mode == .production, check == nil, !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let r = VocabularyChecker.check(c.word, typed: typed, variant: variant)
        check = r
        _ = try? grading.grade(cardID: c.itemID, grade: r.grade, today: now())
    }

    public func next() { advance() }

    private func advance() {
        index += 1
        isRevealed = false
        typed = ""
        check = nil
        updateMode()
    }

    private func updateMode() {
        guard let c = current else { return }
        // Personal words without a translation can't be produced from Russian.
        let m = VocabularyMode.mode(itemID: c.itemID, events: (try? store.allEvents()) ?? [])
        mode = c.word.ru.isEmpty ? .recognition : m
    }

    static func make(_ vocab: VocabularyModel, items: [String]) -> WordSessionModel? {
        let pairs = items.compactMap { id in vocab.word(forItem: id).map { (id, $0) } }
        return pairs.isEmpty ? nil : WordSessionModel(store: vocab.store, items: pairs)
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
