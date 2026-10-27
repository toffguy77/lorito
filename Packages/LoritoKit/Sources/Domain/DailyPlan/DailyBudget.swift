/// The combined cap on new introductions per learning day across item kinds.
/// When the budget binds, kinds are served in the order cards, conjugations,
/// words, CCSE. Quotas for conjugations and words default to 0 until the user
/// enables them (their defaults belong to their own changes).
public struct DailyBudget: Sendable, Equatable {
    public static let defaultTotal = 10
    /// Allocation order when the budget binds.
    public static let order: [ItemKind] = [.card, .conjugation, .word, .ccse]

    public let total: Int
    public let quotas: [ItemKind: Int]

    public init(total: Int = DailyBudget.defaultTotal, quotas: [ItemKind: Int]) {
        self.total = total
        self.quotas = quotas
    }

    /// The standard budget: cards from `dailyNewCardCount`, conjugations from
    /// `dailyConjugationCount` (0 = off); other kinds off until their changes.
    public static func standard(settings: UserSettings) -> DailyBudget {
        DailyBudget(quotas: [.card: max(0, settings.dailyNewCardCount),
                             .conjugation: max(0, settings.dailyConjugationCount)])
    }

    /// Remaining new items per kind for the rest of the day.
    public func allowances(introducedToday: [ItemKind: Int]) -> [ItemKind: Int] {
        var left = max(0, total - Self.order.reduce(0) { $0 + (introducedToday[$1] ?? 0) })
        var out: [ItemKind: Int] = [:]
        for kind in Self.order {
            let quotaLeft = max(0, (quotas[kind] ?? 0) - (introducedToday[kind] ?? 0))
            let granted = min(quotaLeft, left)
            out[kind] = granted
            left -= granted
        }
        return out
    }
}

public extension IntroductionLedger {
    /// Introductions today per kind.
    var countsByKind: [ItemKind: Int] {
        Dictionary(grouping: introducedToday, by: ItemKind.parse).mapValues(\.count)
    }
}
