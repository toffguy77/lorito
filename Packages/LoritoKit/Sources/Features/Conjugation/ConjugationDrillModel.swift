import Foundation
import Observation
import Domain

/// The conjugation drill: one item (verb × tense) at a time, two persons per
/// review chosen by `PersonRotation`; checking grades each answer and the worse
/// one is applied through the shared scheduling operation (`GradingService`),
/// which also writes the study event under the item id.
@MainActor
@Observable
public final class ConjugationDrillModel: Identifiable {
    public let id = UUID()
    private let store: UserDataStore
    private let catalog: ConjugationCatalog
    private let grading: GradingService
    private let now: () -> Date
    let personSet: [Int]
    /// The learner's variant: decides the person set and asks `vos` for Rioplatense.
    public let variant: SpanishVariant
    public let items: [ConjugationItem]

    public private(set) var index = 0
    public private(set) var persons: [Int] = []
    public var answers: [String] = ["", ""]
    /// Per-person results once checked.
    public private(set) var results: [ConjugationCheck]?
    /// Which field the accent row types into.
    public var focusedField = 0

    public init(store: UserDataStore, catalog: ConjugationCatalog, itemIDs: [String],
                variant: SpanishVariant = .spain, today: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.grading = GradingService(store: store)
        self.variant = variant
        self.personSet = PersonRotation.personSet(for: variant)
        self.now = today
        self.items = itemIDs.compactMap { ConjugationItem(id: $0, catalog: catalog) }
        preparePersons()
    }

    public var current: ConjugationItem? { index < items.count ? items[index] : nil }
    public var isComplete: Bool { index >= items.count }
    public var positionText: String { "\(min(index + 1, items.count))/\(items.count)" }
    public var canCheck: Bool { results == nil && answers.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }

    public func expected(_ slot: Int) -> String {
        guard let item = current, slot < persons.count else { return "" }
        return item.form(person: persons[slot], variant: variant)
    }

    /// «yo», «vos», «ellos / ustedes»… for an answer field.
    public func label(_ slot: Int) -> String {
        slot < persons.count ? PersonRotation.label(persons[slot], variant: variant) : ""
    }

    public static let accents = ["á", "é", "í", "ó", "ú", "ñ", "ü"]

    public func insertAccent(_ ch: String) {
        guard results == nil, focusedField < answers.count else { return }
        answers[focusedField] += ch
    }

    public func check() {
        guard canCheck, let item = current else { return }
        let r = persons.indices.map { i in
            ConjugationChecker.check(expected: expected(i), typed: answers[i], reflexive: item.verb.reflexive)
        }
        results = r
        _ = try? grading.grade(cardID: item.id, grade: ConjugationChecker.combined(r.map(\.grade)), today: now())
    }

    public func next() {
        guard results != nil else { return }
        index += 1
        answers = ["", ""]
        results = nil
        focusedField = 0
        preparePersons()
    }

    private func preparePersons() {
        guard let item = current else { persons = []; return }
        let count = PersonRotation.gradedCount(itemID: item.id, events: (try? store.allEvents()) ?? [])
        persons = PersonRotation.persons(itemID: item.id, gradedCount: count, personSet: personSet)
        answers = Array(repeating: "", count: persons.count)
    }
}
