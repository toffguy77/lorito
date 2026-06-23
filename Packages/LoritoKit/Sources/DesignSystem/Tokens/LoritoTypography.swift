import SwiftUI

/// Typography scale for "Modern Calm", built on the system font (SF Pro).
/// Uses relative/text styles so Dynamic Type scales every token.
public enum LoritoFont {
    /// Large screen titles (e.g. card title). Tight tracking.
    public static let title = Font.system(.largeTitle, design: .default).weight(.bold)
    /// Section headings.
    public static let heading = Font.system(.title3, design: .default).weight(.semibold)
    /// Body copy.
    public static let body = Font.system(.body, design: .default)
    /// Secondary/footnote copy.
    public static let caption = Font.system(.footnote, design: .default)
    /// Small uppercase labels (chips, callout headers).
    public static let label = Font.system(.caption2, design: .default).weight(.bold)
}

public extension Text {
    /// Apply a typography token (and the tight tracking the brand uses for titles).
    func loritoStyle(_ font: Font, tracking: CGFloat = 0) -> some View {
        self.font(font).tracking(tracking)
    }
}
