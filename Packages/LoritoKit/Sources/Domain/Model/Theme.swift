// A theme groups a contiguous, ordered set of cards within a level.

public struct Theme: Codable, Sendable, Identifiable, Hashable {
    public let id: String          // e.g. "a1-1"
    public let level: CEFRLevel
    public let title: String       // human-readable, from the level MOC section
    public let order: Int          // 1-based order of the theme within its level

    public init(id: String, level: CEFRLevel, title: String, order: Int) {
        self.id = id
        self.level = level
        self.title = title
        self.order = order
    }
}
