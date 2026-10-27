import Foundation

/// A typed block of a card body. Paragraphs, lists, and tables are kept as
/// `.markdown` spans rendered by `CardBodyView` (MarkdownUI); the four named
/// sections are lifted into typed `.callout` blocks.
public enum CardBlock: Equatable, Sendable {
    case markdown(String)
    case callout(CalloutKind, String)
    /// Another regional variant's block, shown collapsed under its title («В Испании»).
    case variantNote(title: String, String)
}

/// Splits a card's Markdown body into renderable blocks, recognizing the four
/// callout sections (Суть / Ключевые моменты / (Частые) ошибки / Полезно) in
/// either the blockquote form (`> **Суть**`) or the heading form
/// (`## 🔑 Ключевые моменты`). Everything else stays Markdown. Pure.
public enum CardBodyParser {

    /// Blocks for the learner's variant: their variant blocks and inline forms in
    /// place, other variants' blocks as `.variantNote`s where they stood.
    public static func parse(_ body: String, variant: SpanishVariant = .spain) -> [CardBlock] {
        var blocks: [CardBlock] = []
        var shown: [String] = []
        func flush() {
            blocks += parseResolved(VariantMarkup.resolveInline(shown.joined(separator: "\n"), for: variant))
            shown.removeAll()
        }
        for segment in VariantMarkup.segments(body) {
            switch segment {
            case .common(let lines):
                shown += lines
            case .block(let codes, let lines) where codes.contains(variant):
                shown += lines
            case .block(let codes, let lines):
                flush()
                let text = VariantMarkup.resolveInline(lines.joined(separator: "\n"), for: variant)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { blocks.append(.variantNote(title: VariantMarkup.noteTitle(codes), text)) }
            }
        }
        flush()
        return blocks
    }

    private static func parseResolved(_ body: String) -> [CardBlock] {
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

    /// The first item of the "Частые ошибки" section (first bullet, or first
    /// line when it is a paragraph), as Markdown; nil when there is none.
    public static func firstMistake(in body: String) -> String? {
        for block in parse(body) {
            guard case .callout(.mistakes, let content) = block else { continue }
            for line in content.components(separatedBy: "\n") {
                var s = line.trimmingCharacters(in: .whitespaces)
                if s.isEmpty || s.hasPrefix("|") { continue }
                for marker in ["- ", "* ", "+ "] where s.hasPrefix(marker) {
                    s.removeFirst(marker.count)
                    break
                }
                let item = s.trimmingCharacters(in: .whitespaces)
                if !item.isEmpty { return item }
            }
        }
        return nil
    }

    /// Drop decorative emoji that lead Markdown headings ("## 📐 Правило" →
    /// "## Правило"): the brand fonts have no emoji glyphs and Plumaje uses no
    /// emoji as iconography. Content files stay unchanged.
    public static func stripHeadingEmoji(_ markdown: String) -> String {
        markdown.components(separatedBy: "\n").map { line in
            guard headingTitle(line) != nil else { return line }
            let hashes = line.prefix { $0 == "#" || $0 == " " }
            var rest = Substring(line.dropFirst(hashes.count))
            while let first = rest.unicodeScalars.first, isDecorative(first) || first == " " {
                rest = Substring(String(rest.unicodeScalars.dropFirst()))
            }
            return rest.isEmpty ? line : String(hashes) + rest
        }.joined(separator: "\n")
    }

    private static func isDecorative(_ scalar: Unicode.Scalar) -> Bool {
        let p = scalar.properties
        return p.isEmojiPresentation
            || (p.isEmoji && scalar.value > 0x238C)          // pictographs; not digits, #, *
            || scalar.value == 0xFE0F || scalar.value == 0x200D  // variation selector, ZWJ
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
    public static func calloutKind(matching title: String) -> CalloutKind? {
        let s = title.lowercased()
        if s.contains("суть") { return .essence }
        if s.contains("ключев") { return .keyPoints }
        if s.contains("ошибк") { return .mistakes }
        if s.contains("полезно") { return .useful }
        return nil
    }
}

/// The four callout kinds used in card bodies.
public enum CalloutKind: String, CaseIterable, Sendable {
    case essence      // Суть
    case keyPoints    // Ключевые моменты
    case mistakes     // Ошибки
    case useful       // Полезно

    public var title: String {
        switch self {
        case .essence: return "Суть"
        case .keyPoints: return "Ключевые моменты"
        case .mistakes: return "Частые ошибки"
        case .useful: return "Полезно"
        }
    }

    /// Суть is the card's key idea and sits on ink; the rest on `surfaceSunken`.
    public var isOnInk: Bool { self == .essence }
}
