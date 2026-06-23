import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Build a color from a 0xRRGGBB literal. Used only inside the token layer.
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
        #else
        return light
        #endif
    }
}
