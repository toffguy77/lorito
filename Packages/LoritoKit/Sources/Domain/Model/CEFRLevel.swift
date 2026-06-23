// CEFR levels A1..C2, ordered. Pure value type.

public enum CEFRLevel: String, CaseIterable, Codable, Sendable, Comparable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    public var id: String { rawValue }

    /// 0-based rank used for ordering and inclusion.
    public var order: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// This level plus every lower level (selecting a level includes all below it).
    public var included: [CEFRLevel] {
        Self.allCases.filter { $0.order <= order }
    }

    public static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        lhs.order < rhs.order
    }
}
