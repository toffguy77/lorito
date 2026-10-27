import SwiftUI

/// A typography style from `tokens.json` → `font.styles`: a bundled face at a
/// base size that scales with Dynamic Type relative to a system text style.
public struct LoritoTextStyle: Sendable {
    public let postScriptName: String
    public let size: CGFloat
    public let relativeTo: Font.TextStyle
    public let tracking: CGFloat
    public let uppercase: Bool

    /// The SwiftUI font; falls back to the system font of the same text style
    /// when the bundled face is unavailable, so text never disappears.
    public var font: Font {
        FontRegistry.isAvailable(postScriptName)
            ? .custom(postScriptName, size: size, relativeTo: relativeTo)
            : .system(relativeTo)
    }

    // Unbounded — titles, numbers, brand glyphs ¡ ¿.
    public static let display = LoritoTextStyle("Unbounded-ExtraBold", 44, .largeTitle, tracking: -1.5)
    public static let title = LoritoTextStyle("Unbounded-ExtraBold", 34, .largeTitle, tracking: -1.0)
    public static let number = LoritoTextStyle("Unbounded-ExtraBold", 64, .largeTitle, tracking: -2.0)
    public static let heading = LoritoTextStyle("Unbounded-Bold", 22, .title2, tracking: -0.5)
    // Onest — all Russian UI and explanations.
    public static let bodyStrong = LoritoTextStyle("Onest-SemiBold", 17, .body)
    public static let body = LoritoTextStyle("Onest-Regular", 17, .body)
    public static let caption = LoritoTextStyle("Onest-Medium", 13, .footnote)
    public static let label = LoritoTextStyle("Onest-Bold", 12, .caption2, tracking: 1.2, uppercase: true)
    // Instrument Serif Italic — Spanish text only (no Cyrillic glyphs).
    public static let spanish = LoritoTextStyle("InstrumentSerif-Italic", 30, .title)
    public static let spanishInline = LoritoTextStyle("InstrumentSerif-Italic", 20, .body)

    init(_ name: String, _ size: CGFloat, _ relativeTo: Font.TextStyle, tracking: CGFloat = 0, uppercase: Bool = false) {
        self.postScriptName = name
        self.size = size
        self.relativeTo = relativeTo
        self.tracking = tracking
        self.uppercase = uppercase
    }

    /// The same face at a different base size (e.g. a 26 pt Spanish token chip).
    public func sized(_ size: CGFloat) -> LoritoTextStyle {
        LoritoTextStyle(postScriptName, size, relativeTo, tracking: tracking, uppercase: uppercase)
    }
}

/// Typography scale for "Plumaje" (fonts only; use `loritoStyle(_:)` to also
/// apply tracking and casing).
public enum LoritoFont {
    public static var display: Font { LoritoTextStyle.display.font }
    public static var title: Font { LoritoTextStyle.title.font }
    public static var number: Font { LoritoTextStyle.number.font }
    public static var heading: Font { LoritoTextStyle.heading.font }
    public static var body: Font { LoritoTextStyle.body.font }
    public static var bodyStrong: Font { LoritoTextStyle.bodyStrong.font }
    public static var caption: Font { LoritoTextStyle.caption.font }
    public static var label: Font { LoritoTextStyle.label.font }
    /// Spanish words, examples, answers — and nothing else.
    public static var spanish: Font { LoritoTextStyle.spanish.font }
    public static var spanishInline: Font { LoritoTextStyle.spanishInline.font }
}

public extension View {
    /// Wide Unbounded titles: cap growth at the first accessibility size and
    /// allow up to three lines so words never break mid-word.
    func loritoTitleFit(lines: Int = 3) -> some View {
        dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .lineLimit(lines)
            .minimumScaleFactor(0.6)
    }

    /// Apply a typography style: font, tracking, and uppercase where the style
    /// requires it.
    func loritoStyle(_ style: LoritoTextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .textCase(style.uppercase ? .uppercase : nil)
    }
}
