import Foundation

/// A card's first "Частые ошибки" item, offered as the trap of the day.
public struct TrapCandidate: Sendable, Hashable {
    public let cardID: String
    public let text: String

    public init(cardID: String, text: String) {
        self.cardID = cardID
        self.text = text
    }
}

/// Picks the "Ловушка дня" deterministically per calendar day.
public enum DailyTrap {
    /// Prefers candidates the user has studied; index = stableHash(yyyy-MM-dd)
    /// mod count over candidates sorted by card id. Nil when there are none.
    public static func pick(candidates: [TrapCandidate], studiedIDs: Set<String>, day: Date,
                            calendar: Calendar = .learningDay) -> TrapCandidate? {
        let studied = candidates.filter { studiedIDs.contains($0.cardID) }
        let pool = (studied.isEmpty ? candidates : studied).sorted { $0.cardID < $1.cardID }
        guard !pool.isEmpty else { return nil }
        let index = Int(stableHash(dayKey(day, calendar: calendar)) % UInt64(pool.count))
        return pool[index]
    }

    /// "yyyy-MM-dd" of the learning day — the same day calendar as the daily plan.
    static func dayKey(_ day: Date, calendar: Calendar = .learningDay) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// 64-bit FNV-1a — stable across launches and devices (unlike `hashValue`).
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
