import Foundation
import Testing
@testable import DesignSystem

/// Parses `design/brand/tokens.json` (the source of truth) and checks the
/// Swift token layer mirrors it.
private enum TokenSource {
    static let url: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()      // DesignSystemTests
        .deletingLastPathComponent()      // Tests
        .deletingLastPathComponent()      // LoritoKit
        .deletingLastPathComponent()      // Packages
        .deletingLastPathComponent()      // repo root
        .appendingPathComponent("design/brand/tokens.json")

    static func json() throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// name → (light, dark) as 0xRRGGBB.
    static func colors() throws -> [String: (light: UInt32, dark: UInt32)] {
        let color = try #require(json()["color"] as? [String: [String: String]])
        var out: [String: (UInt32, UInt32)] = [:]
        for (name, values) in color {
            let light = try #require(values["light"].flatMap(parseHex))
            let dark = try #require(values["dark"].flatMap(parseHex))
            out[name] = (light, dark)
        }
        return out
    }

    static func parseHex(_ s: String) -> UInt32? {
        UInt32(s.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16)
    }
}

/// WCAG 2.x relative luminance / contrast ratio.
enum Contrast {
    static func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel((hex >> 16) & 0xFF)
            + 0.7152 * channel((hex >> 8) & 0xFF)
            + 0.0722 * channel(hex & 0xFF)
    }

    static func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}

@Suite("Plumaje color tokens")
struct ColorTokenTests {
    @Test("Every tokens.json color exists in LoritoColor with matching light/dark hex")
    func tokensMatchSource() throws {
        let source = try TokenSource.colors()
        #expect(!source.isEmpty)
        for (name, values) in source {
            let token = try #require(LoritoColor.palette[name], "missing token \(name)")
            #expect(token.light == values.light, "\(name) light")
            #expect(token.dark == values.dark, "\(name) dark")
        }
        #expect(Set(LoritoColor.palette.keys) == Set(source.keys), "token set differs from tokens.json")
    }

    @Test("Accent is parrot green in light")
    func accentIsLoro() {
        #expect(LoritoColor.palette["accent"]?.light == 0x0E7C47)
    }

    @Test("Focus surfaces are appearance-independent")
    func focusSurfacesFixed() throws {
        for name in ["ink", "onInk", "onInkSecondary", "inkRaised", "inkTrack"] {
            let token = try #require(LoritoColor.palette[name])
            #expect(token.light == token.dark, "\(name) differs between themes")
        }
        #expect(LoritoColor.palette["ink"]?.light == 0x0F1A14)
    }

    /// Documented text pairings (foreground, background).
    static let textPairs: [(String, String)] = [
        ("textPrimary", "surface"),
        ("textPrimary", "surfaceRaised"),
        ("textSecondary", "surface"),
        ("textSecondary", "surfaceRaised"),
        ("textTertiary", "surfaceRaised"),
        ("onAccent", "accent"),
        ("onAccentSoft", "accentSoft"),
        ("onHighlight", "highlight"),
        ("onInk", "ink"),
        ("onInkSecondary", "ink"),
        ("onInk", "inkRaised"),
        ("dangerText", "dangerSoft"),
        ("accent", "surfaceRaised"),
        ("textSecondary", "surfaceSunken"),
        ("onAccentSoft", "surfaceSunken"),
        ("dangerText", "surfaceSunken"),
        ("dangerText", "surfaceRaised"),
        ("highlight", "ink"),
        ("onInkSecondary", "inkRaised"),
    ]

    @Test("Text pairings meet 4.5:1 in light and dark")
    func contrast() throws {
        let p = LoritoColor.palette
        for (fg, bg) in Self.textPairs {
            let f = try #require(p[fg]), b = try #require(p[bg])
            let light = Contrast.ratio(f.light, b.light)
            let dark = Contrast.ratio(f.dark, b.dark)
            #expect(light >= 4.5, "\(fg) on \(bg) light = \(light)")
            #expect(dark >= 4.5, "\(fg) on \(bg) dark = \(dark)")
        }
    }
}

@Suite("Plumaje layout tokens")
struct LayoutTokenTests {
    @Test("Spacing, radius and layout mirror tokens.json")
    func layoutMatchesSource() throws {
        let json = try TokenSource.json()
        let spacing = try #require(json["spacing"] as? [String: Double])
        #expect(Double(LoritoSpacing.screenGutter) == spacing["screenGutter"])
        #expect(Double(LoritoSpacing.md) == spacing["md"])
        let radius = try #require(json["radius"] as? [String: Double])
        #expect(Double(LoritoRadius.sm) == radius["sm"])
        #expect(Double(LoritoRadius.md) == radius["md"])
        #expect(Double(LoritoRadius.lg) == radius["lg"])
        #expect(Double(LoritoRadius.xl) == radius["xl"])
        let layout = try #require(json["layout"] as? [String: Double])
        #expect(Double(LoritoLayout.minTouchTarget) == layout["minTouchTarget"])
        #expect(Double(LoritoLayout.primaryButtonHeight) == layout["primaryButtonHeight"])
        #expect(Double(LoritoLayout.tabBarHeight) == layout["tabBarHeight"])
        #expect(Double(LoritoLayout.readingWidth) == layout["readingWidth"])
    }
}
