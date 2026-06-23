import SwiftUI

/// Spacing scale (4-pt based).
public enum LoritoSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
}

/// Corner-radius scale.
public enum LoritoRadius {
    public static let sm: CGFloat = 10
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let pill: CGFloat = 999
}

/// Elevation (shadow) tokens.
public struct LoritoElevation: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let y: CGFloat

    public static let card = LoritoElevation(
        color: Color.black.opacity(0.10), radius: 18, y: 10
    )
}

public extension View {
    /// Apply an elevation token as a shadow.
    func loritoElevation(_ elevation: LoritoElevation = .card) -> some View {
        shadow(color: elevation.color, radius: elevation.radius, x: 0, y: elevation.y)
    }
}
