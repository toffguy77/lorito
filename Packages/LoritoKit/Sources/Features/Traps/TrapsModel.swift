import Foundation
import Observation
import Domain

/// «Мои ловушки»: the user's in-scope personal traps, ranked.
@MainActor
@Observable
public final class TrapsModel {
    let store: UserDataStore
    let catalog: ContentCatalog
    private let now: () -> Date
    public private(set) var traps: [PersonalTrap] = []
    public var showAll = false

    public init(store: UserDataStore, catalog: ContentCatalog, today: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.now = today
        refresh()
    }

    public func refresh() {
        traps = PersonalTraps.list(events: (try? store.allEvents()) ?? [], practice: (try? store.allTrapPractice()) ?? [],
                                   catalog: catalog, settings: (try? store.loadSettings()) ?? .default, today: now())
    }

    /// Top 20 until «показать все».
    public var visible: [PersonalTrap] { showAll ? traps : Array(traps.prefix(TrapConstants.listPreview)) }
    public var hasMore: Bool { !showAll && traps.count > TrapConstants.listPreview }

    public func card(_ trap: PersonalTrap) -> Card? { catalog.card(id: trap.cardID) }

    public func makeSession() -> TrapsSessionModel? {
        let picked = Array(traps.prefix(TrapConstants.sessionSize))
        return picked.isEmpty ? nil : TrapsSessionModel(store: store, catalog: catalog, traps: picked, today: now)
    }

    /// «1 ловушка / 2 ловушки / 5 ловушек»
    public static func countLabel(_ n: Int) -> String {
        "\(n) \(RussianPlural.form(n, one: "ловушка", few: "ловушки", many: "ловушек"))"
    }
}

/// The traps session (focus mode, not SRS): front = first mistakes item,
/// reveal = the whole «Частые ошибки» section; «Ещё путаю» / «Ясно» write a
/// `TrapPracticeEvent` only.
@MainActor
@Observable
public final class TrapsSessionModel: Identifiable {
    public let id = UUID()
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let now: () -> Date
    public let traps: [PersonalTrap]
    public private(set) var index = 0
    public private(set) var isRevealed = false

    init(store: UserDataStore, catalog: ContentCatalog, traps: [PersonalTrap], today: @escaping () -> Date) {
        self.store = store
        self.catalog = catalog
        self.traps = traps
        self.now = today
    }

    public var current: PersonalTrap? { index < traps.count ? traps[index] : nil }
    public var isComplete: Bool { index >= traps.count }
    public var positionText: String { "\(min(index + 1, traps.count))/\(traps.count)" }
    public var currentCard: Card? { current.flatMap { catalog.card(id: $0.cardID) } }

    /// The full «Частые ошибки» section of the current card.
    public var mistakesSection: String {
        guard let body = currentCard?.body else { return "" }
        for block in CardBodyParser.parse(body) {
            if case .callout(.mistakes, let content) = block { return content }
        }
        return current?.firstMistake ?? ""
    }

    public func reveal() { isRevealed = true }

    public func answer(_ outcome: TrapPracticeEvent.Outcome) {
        guard let trap = current, isRevealed else { return }
        try? store.appendTrapPractice(TrapPracticeEvent(cardID: trap.cardID, date: now(), outcome: outcome))
        index += 1
        isRevealed = false
    }
}
