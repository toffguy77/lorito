import SwiftUI

/// Spacing scale (4-pt based). Mirrors `tokens.json` → `spacing`.
public enum LoritoSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    /// Horizontal inset of screen content from the device edges.
    public static let screenGutter: CGFloat = 20
}

/// Layout constraints. Mirrors `tokens.json` → `layout`.
public enum LoritoLayout {
    /// Maximum comfortable width for reading / primary content columns. Caps
    /// content on large screens (iPad); narrower devices fill the width.
    public static let readingWidth: CGFloat = 640
    /// Minimum side of any tappable control.
    public static let minTouchTarget: CGFloat = 44
    /// Height of the primary pill button.
    public static let primaryButtonHeight: CGFloat = 56
    /// Height of the floating tab bar capsule.
    public static let tabBarHeight: CGFloat = 64
}

/// Corner-radius scale. Mirrors `tokens.json` → `radius`.
public enum LoritoRadius {
    public static let sm: CGFloat = 14
    public static let md: CGFloat = 20
    public static let lg: CGFloat = 28
    public static let xl: CGFloat = 36
    public static let pill: CGFloat = 999
}

/// Elevation (shadow) tokens. Mirrors `tokens.json` → `elevation`.
public struct LoritoElevation: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let y: CGFloat

    /// Raised cards on `surface`.
    public static let card = LoritoElevation(color: LoritoColor.ink.opacity(0.12), radius: 32, y: 12)
    /// The floating tab bar.
    public static let tabBar = LoritoElevation(color: LoritoColor.ink.opacity(0.12), radius: 32, y: 12)
}

public extension View {
    /// Apply an elevation token as a shadow. CSS blur radius ≈ 2× SwiftUI radius.
    func loritoElevation(_ elevation: LoritoElevation = .card) -> some View {
        shadow(color: elevation.color, radius: elevation.radius / 2, x: 0, y: elevation.y)
    }
}
