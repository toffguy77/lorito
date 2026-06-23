// A study card: structured metadata + a Markdown body.

public struct Card: Codable, Sendable, Identifiable, Hashable {
    public let id: String            // e.g. "A1-15"
    public let level: CEFRLevel
    public let themeID: String       // references Theme.id
    public let order: Int            // 1-based order within the level
    public let title: String
    public let aliases: [String]
    public let related: [String]     // other card ids
    public let tags: [String]
    public let body: String          // Markdown

    public init(
        id: String,
        level: CEFRLevel,
        themeID: String,
        order: Int,
        title: String,
        aliases: [String] = [],
        related: [String] = [],
        tags: [String] = [],
        body: String
    ) {
        self.id = id
        self.level = level
        self.themeID = themeID
        self.order = order
        self.title = title
        self.aliases = aliases
        self.related = related
        self.tags = tags
        self.body = body
    }
}
