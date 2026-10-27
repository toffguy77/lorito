import SwiftUI

/// Spanish spans in Markdown: emphasis containing a Latin letter (`*el libro*`)
/// becomes a `lorito-es://span?text=…` link, so taps reach one `OpenURLAction`
/// and every feature shares one gesture contract. Pure string helpers.
public enum SpanishSpans {
    public static let scheme = "lorito-es"

    /// True when the text has a Latin letter (numbers and quotes stay plain).
    nonisolated public static func isSpanish(_ text: String) -> Bool {
        text.unicodeScalars.contains { s in
            s.properties.isAlphabetic
                && ((0x41...0x5A).contains(s.value) || (0x61...0x7A).contains(s.value)
                    || (0xC0...0x24F).contains(s.value))
        }
    }

    nonisolated public static func url(for text: String) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = "span"
        c.queryItems = [URLQueryItem(name: "text", value: text)]
        return c.url!
    }

    nonisolated public static func text(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == "span" else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "text" }?.value
    }

    /// Code spans and existing links (left alone) or single-asterisk emphasis.
    nonisolated private static let pattern = try! NSRegularExpression(pattern:
        #"(`[^`\n]*`)|(\[[^\]\n]*\]\([^)\n]*\))|(?<![*\w])\*(?![\s*])([^*\n]+?)(?<![\s*])\*(?![*\w])"#)

    /// Wrap each Spanish emphasis in a span link; everything else is unchanged.
    nonisolated public static func link(_ markdown: String) -> String {
        let ns = markdown as NSString
        var out = ""
        var last = 0
        for m in pattern.matches(in: markdown, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            let whole = ns.substring(with: m.range)
            if m.range(at: 3).location != NSNotFound {
                let inner = ns.substring(with: m.range(at: 3))
                out += isSpanish(inner) ? "[\(whole)](\(url(for: inner).absoluteString))" : whole
            } else {
                out += whole
            }
            last = m.range.location + m.range.length
        }
        return out + ns.substring(from: last)
    }

    /// The distinct Spanish spans of a block, in order.
    nonisolated public static func spans(in markdown: String) -> [String] {
        let ns = markdown as NSString
        var seen = Set<String>(), out: [String] = []
        for m in pattern.matches(in: markdown, range: NSRange(location: 0, length: ns.length))
        where m.range(at: 3).location != NSNotFound {
            let inner = ns.substring(with: m.range(at: 3))
            if isSpanish(inner), seen.insert(inner).inserted { out.append(inner) }
        }
        return out
    }
}

/// An action features contribute for Spanish spans («Произнести», «В мои слова»…).
public struct SpanishSpanAction: Identifiable, @unchecked Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    /// The tap action (one primary at most; the first registered wins).
    public let isPrimary: Bool
    public let perform: @MainActor (String) -> Void

    public init(id: String, title: String, systemImage: String, isPrimary: Bool = false,
                perform: @escaping @MainActor (String) -> Void) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isPrimary = isPrimary
        self.perform = perform
    }
}

/// The registry of span actions, carried in the environment. Features add items
/// with `.spanishSpanAction(_:)`; they never attach their own gestures.
public struct SpanishSpanActions: Sendable {
    public private(set) var menuItems: [SpanishSpanAction] = []

    public init() {}

    public mutating func register(_ action: SpanishSpanAction) {
        guard !menuItems.contains(where: { $0.id == action.id }) else { return }
        menuItems.append(action)
    }

    /// Run the primary action; false (and nothing happens) when none is registered.
    @MainActor @discardableResult
    public func performPrimary(_ text: String) -> Bool {
        guard let primary = menuItems.first(where: \.isPrimary) else { return false }
        primary.perform(text)
        return true
    }
}

public extension EnvironmentValues {
    @Entry var spanishSpanActions = SpanishSpanActions()
}

public extension View {
    /// Contribute an action to every Spanish span below this view.
    func spanishSpanAction(_ action: SpanishSpanAction) -> some View {
        transformEnvironment(\.spanishSpanActions) { $0.register(action) }
    }

    /// Long-press menu and VoiceOver actions for the Spanish spans of a block.
    func spanishSpanMenu(spans: [String], actions: SpanishSpanActions) -> some View {
        modifier(SpanishSpanMenu(spans: spans, actions: actions))
    }
}

private struct SpanishSpanMenu: ViewModifier {
    let spans: [String]
    let actions: SpanishSpanActions

    func body(content: Content) -> some View {
        if spans.isEmpty || actions.menuItems.isEmpty {
            content
        } else {
            content
                .contextMenu {
                    ForEach(spans, id: \.self) { span in
                        Section(span) {
                            ForEach(actions.menuItems) { item in
                                Button(item.title, systemImage: item.systemImage) { item.perform(span) }
                            }
                        }
                    }
                }
                .accessibilityActions {
                    ForEach(spans, id: \.self) { span in
                        ForEach(actions.menuItems) { item in
                            Button("\(item.title): \(span)") { item.perform(span) }
                        }
                    }
                }
        }
    }
}
