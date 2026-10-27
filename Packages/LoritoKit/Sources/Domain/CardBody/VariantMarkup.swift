import Foundation

/// One form of an inline alternative (`{es: coche | am: carro}`).
public struct VariantForm: Equatable, Sendable {
    public let variant: SpanishVariant
    public let text: String

    public init(variant: SpanishVariant, text: String) {
        self.variant = variant
        self.text = text
    }
}

/// Regional-variant markup in card bodies (see `content/schema.md`): blocks
/// `:::variant <codes>` … `:::` and inline `{es: … | am: … | rio: …}`. Braces
/// without a known `code:` prefix stay text. Pure.
public enum VariantMarkup {
    /// A run of body lines: shared, or a block for the listed variants.
    enum Segment: Equatable {
        case common([String])
        case block([SpanishVariant], [String])
    }

    /// Splits a body into shared runs and variant blocks. An unclosed block
    /// runs to the end (the pipeline rejects it; the app stays readable).
    static func segments(_ body: String) -> [Segment] {
        var out: [Segment] = []
        var common: [String] = []
        var block: (codes: [SpanishVariant], lines: [String])?
        for line in body.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if block == nil, t.hasPrefix(":::variant") {
                let codes = t.dropFirst(":::variant".count).split(separator: " ").compactMap { SpanishVariant(code: String($0)) }
                if !common.isEmpty { out.append(.common(common)); common = [] }
                block = (codes, [])
            } else if block != nil, t == ":::" {
                out.append(.block(block!.codes, block!.lines))
                block = nil
            } else if block != nil {
                block!.lines.append(line)
            } else {
                common.append(line)
            }
        }
        if let block { out.append(.block(block.codes, block.lines)) }
        if !common.isEmpty { out.append(.common(common)) }
        return out
    }

    /// «В Испании», «В Латинской Америке», «В Аргентине и Уругвае»; Rioplatense
    /// is part of Latin America, so `am rio` reads «В Латинской Америке».
    public static func noteTitle(_ codes: [SpanishVariant]) -> String {
        var places = SpanishVariant.allCases.filter(codes.contains)
        if places.contains(.latinAmerica) { places.removeAll { $0 == .rioplatense } }
        let names = places.map(\.notePlace)
        let joined = names.count > 1
            ? names.dropLast().joined(separator: ", ") + " и " + names.last!
            : names.first ?? ""
        return "В " + joined
    }

    // MARK: - Inline alternatives

    nonisolated(unsafe) private static let inline = try! NSRegularExpression(pattern: #"\{\s*([A-Za-z]+)\s*:[^{}\n]*\}"#)

    /// The forms of an inline group, or nil when it isn't variant markup.
    static func forms(_ group: String) -> [VariantForm]? {
        let inner = group.dropFirst().dropLast()
        var out: [VariantForm] = []
        for part in inner.split(separator: "|") {
            let pair = part.split(separator: ":", maxSplits: 1)
            guard pair.count == 2, let v = SpanishVariant(code: pair[0].trimmingCharacters(in: .whitespaces)) else { return nil }
            out.append(VariantForm(variant: v, text: pair[1].trimmingCharacters(in: .whitespaces)))
        }
        return out.count >= 2 ? out : nil
    }

    /// The learner's form (fallback `es`, then the first) without emphasis markers.
    static func pick(_ forms: [VariantForm], for variant: SpanishVariant) -> String {
        let f = forms.first { $0.variant == variant } ?? forms.first { $0.variant == .spain } ?? forms[0]
        return f.text.replacingOccurrences(of: "*", with: "")
    }

    private static func eachGroup(_ text: String, _ body: (NSRange, [VariantForm]) -> Void) {
        let ns = text as NSString
        for m in inline.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            if let forms = forms(ns.substring(with: m.range)) { body(m.range, forms) }
        }
    }

    /// Replaces each inline group with the learner's form as a Spanish span (`*carro*`).
    public static func resolveInline(_ text: String, for variant: SpanishVariant) -> String {
        var out = text as NSString
        var groups: [(NSRange, [VariantForm])] = []
        eachGroup(text) { groups.append(($0, $1)) }
        for (range, forms) in groups.reversed() {
            out = out.replacingCharacters(in: range, with: "*\(pick(forms, for: variant))*") as NSString
        }
        return out as String
    }

    /// Every inline group's forms, keyed by the learner's displayed form.
    public static func alternatives(in body: String, for variant: SpanishVariant) -> [String: [VariantForm]] {
        var out: [String: [VariantForm]] = [:]
        eachGroup(body) { _, forms in
            out[pick(forms, for: variant)] = forms.map { VariantForm(variant: $0.variant, text: $0.text.replacingOccurrences(of: "*", with: "")) }
        }
        return out
    }
}
