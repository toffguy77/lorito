import SwiftUI

/// A typed block of a card body. Paragraphs, lists, and tables are kept as
/// `.markdown` spans rendered by `CardBodyView` (MarkdownUI); the four named
/// sections are lifted into typed `.callout` blocks.
public enum CardBlock: Equatable, Sendable {
    case markdown(String)
    case callout(CalloutKind, String)
}

/// Splits a card's Markdown body into renderable blocks, recognizing the four
/// callout sections (Суть / Ключевые моменты / (Частые) ошибки / Полезно) in
/// either the blockquote form (`> **Суть**`) or the heading form
/// (`## 🔑 Ключевые моменты`). Everything else stays Markdown. Pure.
public enum CardBodyParser {

    public static func parse(_ body: String) -> [CardBlock] {
        let lines = body.components(separatedBy: "\n")
        var blocks: [CardBlock] = []
        var markdown: [String] = []

        func flushMarkdown() {
            let text = markdown.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { blocks.append(.markdown(text)) }
            markdown.removeAll()
        }

        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Blockquote callout: a run of `>` lines whose first is a bold title.
            if isBlockquote(line) {
                var quote: [String] = []
                var j = i
                while j < lines.count, isBlockquote(lines[j]) {
                    quote.append(lines[j]); j += 1
                }
                let title = dequote(quote[0])
                if title.hasPrefix("**"), let kind = calloutKind(matching: title) {
                    flushMarkdown()
                    let content = quote.dropFirst().map(dequote)
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    blocks.append(.callout(kind, content))
                } else {
                    markdown.append(contentsOf: quote)
                }
                i = j
                continue
            }

            // Heading callout: a heading whose title matches a callout kind.
            if let heading = headingTitle(line), let kind = calloutKind(matching: heading) {
                flushMarkdown()
                var content: [String] = []
                var j = i + 1
                while j < lines.count, headingTitle(lines[j]) == nil {
                    content.append(lines[j]); j += 1
                }
                blocks.append(.callout(
                    kind,
                    content.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                ))
                i = j
                continue
            }

            markdown.append(line)
            i += 1
        }
        flushMarkdown()
        return blocks
    }

    // MARK: - Helpers

    private static func isBlockquote(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix(">")
    }

    /// Strip one leading `>` and surrounding whitespace from a blockquote line.
    private static func dequote(_ line: String) -> String {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix(">") { s.removeFirst() }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Title text of a heading line (`#{1,6} text`), or nil if not a heading.
    private static func headingTitle(_ line: String) -> String? {
        let s = line.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("#") else { return nil }
        let hashes = s.prefix { $0 == "#" }
        guard hashes.count <= 6 else { return nil }
        let rest = s.dropFirst(hashes.count)
        guard rest.first == " " else { return nil }
        return rest.trimmingCharacters(in: .whitespaces)
    }

    /// Map a heading/blockquote title to a callout kind by keyword (emoji and
    /// punctuation are ignored by the substring match).
    static func calloutKind(matching title: String) -> CalloutKind? {
        let s = title.lowercased()
        if s.contains("суть") { return .essence }
        if s.contains("ключев") { return .keyPoints }
        if s.contains("ошибк") { return .mistakes }
        if s.contains("полезно") { return .useful }
        return nil
    }
}

/// Renders a card body as a sequence of Markdown spans and typed callout blocks.
/// Shared by the study session and the catalog card reader so a card looks
/// identical in both.
public struct CardContentView: View {
    private let blocks: [CardBlock]

    public init(_ body: String) {
        self.blocks = CardBodyParser.parse(body)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .markdown(let md):
                    CardBodyView(md)
                case .callout(let kind, let md):
                    CalloutBlock(kind) { CardBodyView(md) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
