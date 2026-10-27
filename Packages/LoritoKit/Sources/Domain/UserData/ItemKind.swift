import Foundation

/// The kind of a reviewable item, read from its identifier. The prefix is the
/// contract, so stored data needs no extra field or migration.
public enum ItemKind: String, Codable, Sendable, Hashable, CaseIterable {
    /// Grammar card: `A1-07`.
    case card
    /// Conjugation drill: `conj:<verb>:<tense>`.
    case conjugation
    /// Vocabulary word: `word:<lemma>`.
    case word
    /// CCSE question: `ccse:<id>`.
    case ccse
    /// Anything else — kept in storage, ignored by planners.
    case unknown

    public static func parse(_ id: String) -> ItemKind {
        if isCardID(id) { return .card }
        let parts = id.split(separator: ":", omittingEmptySubsequences: false)
        switch parts.first {
        case "conj" where parts.count == 3 && parts.dropFirst().allSatisfy({ !$0.isEmpty }): return .conjugation
        case "word" where parts.count >= 2 && !parts[1].isEmpty: return .word
        case "ccse" where parts.count == 2 && !parts[1].isEmpty: return .ccse
        default: return .unknown
        }
    }

    /// `^[A-C][12]-\d{2}$`
    private static func isCardID(_ id: String) -> Bool {
        let s = Array(id.utf8)
        guard s.count == 5 else { return false }
        let digit: (UInt8) -> Bool = { $0 >= 48 && $0 <= 57 }
        return (65...67).contains(s[0]) && (s[1] == 49 || s[1] == 50) && s[2] == 45 && digit(s[3]) && digit(s[4])
    }
}

public extension StudyEvent {
    var kind: ItemKind { ItemKind.parse(cardID) }
    var isCard: Bool { kind == .card }
}

public extension ReviewState {
    var kind: ItemKind { ItemKind.parse(cardID) }
}
