import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A token's sRGB values (0xRRGGBB) per appearance.
public struct LoritoColorValue: Sendable, Equatable {
    public let light: UInt32
    public let dark: UInt32
}

/// Semantic color tokens for the "Plumaje" design system. Values mirror
/// `design/brand/tokens.json` (the source of truth).
///
/// Call sites MUST use these tokens, never raw `Color(hex:)`/literals. Each token
/// resolves to a light- and dark-appropriate value; focus surfaces (`ink*`,
/// `onInk*`) are identical in both.
public enum LoritoColor {
    /// Every token by its `tokens.json` name.
    public static let palette: [String: LoritoColorValue] = [
        // Surfaces
        "surface":        .init(light: 0xF3F4EF, dark: 0x0F1A14),
        "surfaceRaised":  .init(light: 0xFFFFFF, dark: 0x17241C),
        "surfaceSunken":  .init(light: 0xE7EAE3, dark: 0x1C2A22),
        "separator":      .init(light: 0xDDE1DA, dark: 0x2A3B31),
        // Text
        "textPrimary":    .init(light: 0x0F1A14, dark: 0xF3F4EF),
        "textSecondary":  .init(light: 0x56625B, dark: 0xA9B5AD),
        "textTertiary":   .init(light: 0x66726B, dark: 0x8A968F),
        // Accent (Loro)
        "accent":         .init(light: 0x0E7C47, dark: 0x3BB273),
        "onAccent":       .init(light: 0xFFFFFF, dark: 0x0F1A14),
        "accentSoft":     .init(light: 0xE4F3EA, dark: 0x16301F),
        "onAccentSoft":   .init(light: 0x0A5C35, dark: 0x9FD9B6),
        // Highlight (Lima)
        "highlight":      .init(light: 0xCBEF6B, dark: 0xCBEF6B),
        "onHighlight":    .init(light: 0x0F1A14, dark: 0x0F1A14),
        // Ink (Tinta) — focus surfaces
        "ink":            .init(light: 0x0F1A14, dark: 0x0F1A14),
        "onInk":          .init(light: 0xF3F4EF, dark: 0xF3F4EF),
        "onInkSecondary": .init(light: 0xA9B5AD, dark: 0xA9B5AD),
        "inkRaised":      .init(light: 0x1C2A22, dark: 0x1C2A22),
        "inkTrack":       .init(light: 0x33443A, dark: 0x33443A),
        // Danger (Chile)
        "danger":         .init(light: 0xE5482A, dark: 0xFF7A5C),
        "dangerText":     .init(light: 0xB93519, dark: 0xFF9B85),
        "dangerSoft":     .init(light: 0xFBE3DD, dark: 0x3A1F19),
        // Activity scale
        "heat0":          .init(light: 0xE7EAE3, dark: 0x1C2A22),
        "heat1":          .init(light: 0x9FD9B6, dark: 0x1E5A3A),
        "heat2":          .init(light: 0x3BB273, dark: 0x2E9A60),
        "heat3":          .init(light: 0x0A5C35, dark: 0xCBEF6B),
    ]

    // Surfaces
    public static let surface = token("surface")
    public static let surfaceRaised = token("surfaceRaised")
    public static let surfaceSunken = token("surfaceSunken")
    public static let separator = token("separator")

    // Text
    public static let textPrimary = token("textPrimary")
    public static let textSecondary = token("textSecondary")
    /// Placeholders only.
    public static let textTertiary = token("textTertiary")

    // Accent — primary brand green; also the Spanish-text color.
    public static let accent = token("accent")
    public static let onAccent = token("onAccent")
    public static let accentSoft = token("accentSoft")
    public static let onAccentSoft = token("onAccentSoft")

    // Highlight — primary CTA on ink, streak, success moments.
    public static let highlight = token("highlight")
    public static let onHighlight = token("onHighlight")

    // Ink — hero cards; focus-mode background in both themes.
    public static let ink = token("ink")
    public static let onInk = token("onInk")
    public static let onInkSecondary = token("onInkSecondary")
    public static let inkRaised = token("inkRaised")
    public static let inkTrack = token("inkTrack")

    // Danger — `danger` for glyphs and large marks only; `dangerText` for text.
    public static let danger = token("danger")
    public static let dangerText = token("dangerText")
    public static let dangerSoft = token("dangerSoft")

    // Activity heatmap scale (least → most).
    public static let heat0 = token("heat0")
    public static let heat1 = token("heat1")
    public static let heat2 = token("heat2")
    public static let heat3 = token("heat3")

    private static func token(_ name: String) -> Color {
        guard let value = palette[name] else { preconditionFailure("unknown color token \(name)") }
        return .dynamic(light: Color(hex: value.light), dark: Color(hex: value.dark))
    }
}

private extension Color {
    /// Build a color from a 0xRRGGBB literal. Private to the token layer.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    /// A color that resolves differently in light and dark appearances.
    static func dynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}
