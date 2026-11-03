import Foundation

/// A free-practice mode (practice-hub): exercises outside a card's reader.
public enum PracticeMode: Hashable, Sendable {
    case mixed
    case weakSpots
    case theme(String)
    case level(CEFRLevel)

    public var name: PracticeModeName {
        switch self {
        case .mixed: .mixed
        case .weakSpots: .weak
        case .theme: .theme
        case .level: .level
        }
    }
}

/// «доступно X из Y»: eligible exercises of a scope, of all its exercises.
public struct PracticeAvailability: Equatable, Sendable {
    public let available: Int
    public let total: Int

    public init(available: Int, total: Int) {
        self.available = available
        self.total = total
    }
}

/// Picks exercises for free practice. Pure: catalog, review states and attempts
/// in, exercises out. Only exercises of studied cards are eligible, so free
/// practice never introduces a new card.
public enum PracticeSelector {
    /// Cap for mixed, weak-spot and level sessions (theme sessions are uncapped).
    public static let sessionLimit = 20

    /// A card the user has studied: learning or review, or suspended after it was graded.
    public static func isStudied(_ review: ReviewState?) -> Bool {
        guard let review else { return false }
        switch review.status {
        case .learning, .review: return true
        case .suspended: return review.lastGrade != nil || review.repetitions > 0 || review.lastReviewDate != nil
        case .new: return false
        }
    }

    /// The exercises a mode draws from, before the studied-card filter.
    public static func scope(_ mode: PracticeMode, catalog: ContentCatalog,
                             attempts: [ExerciseAttempt]) -> [Exercise] {
        switch mode {
        case .mixed: return catalog.exercises
        case .theme(let id): return catalog.exercises(themeID: id)
        case .level(let level): return catalog.exercises(in: level)
        case .weakSpots:
            let missed = Set(lastAttempts(attempts).filter { !$0.value.correct }.keys)
            return catalog.exercises.filter { missed.contains($0.id) }
        }
    }

    public static func availability(_ mode: PracticeMode, catalog: ContentCatalog,
                                    reviews: [String: ReviewState], attempts: [ExerciseAttempt]) -> PracticeAvailability {
        let all = scope(mode, catalog: catalog, attempts: attempts)
        return PracticeAvailability(available: all.filter { isStudied(reviews[$0.card]) }.count, total: all.count)
    }

    /// The session's exercises for a mode. `seed` makes the mixed/level shuffle
    /// deterministic (tests inject it; the app passes a random one).
    public static func select(_ mode: PracticeMode, catalog: ContentCatalog,
                              reviews: [String: ReviewState], attempts: [ExerciseAttempt],
                              seed: UInt64) -> [Exercise] {
        let eligible = scope(mode, catalog: catalog, attempts: attempts).filter { isStudied(reviews[$0.card]) }
        let last = lastAttempts(attempts)
        switch mode {
        case .theme:
            let order = Dictionary(catalog.cards.map { ($0.id, $0.order) }, uniquingKeysWith: { a, _ in a })
            return eligible.sorted { (order[$0.card] ?? 0, $0.id) < (order[$1.card] ?? 0, $1.id) }
        case .weakSpots:
            return Array(eligible.sorted {
                let (a, b) = (last[$0.id]!.date, last[$1.id]!.date)
                return a != b ? a > b : $0.id < $1.id
            }.prefix(sessionLimit))
        case .mixed, .level:
            var rng = SplitMix64(seed: seed)
            let shuffled = eligible.shuffled(using: &rng)
            let rank = Dictionary(shuffled.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
            let picked = shuffled.sorted {
                let (a, b) = (last[$0.id]?.date ?? .distantPast, last[$1.id]?.date ?? .distantPast)
                return a != b ? a < b : rank[$0.id]! < rank[$1.id]!
            }.prefix(sessionLimit)
            return spreadCards(Array(picked))
        }
    }

    /// The latest attempt per exercise id.
    static func lastAttempts(_ attempts: [ExerciseAttempt]) -> [String: ExerciseAttempt] {
        var last: [String: ExerciseAttempt] = [:]
        for a in attempts where last[a.exerciseID].map({ a.date >= $0.date }) ?? true {
            last[a.exerciseID] = a
        }
        return last
    }

    /// Reorder so two exercises of the same card are not adjacent when another choice exists.
    static func spreadCards(_ items: [Exercise]) -> [Exercise] {
        var remaining = items
        var result: [Exercise] = []
        while !remaining.isEmpty {
            let i = remaining.firstIndex { $0.card != result.last?.card } ?? 0
            result.append(remaining.remove(at: i))
        }
        return result
    }
}
