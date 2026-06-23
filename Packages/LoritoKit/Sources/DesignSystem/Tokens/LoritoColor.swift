import SwiftUI

/// Semantic color tokens for the "Modern Calm" design system.
///
/// Call sites MUST use these tokens, never raw `Color(hex:)`/literals. Each token
/// resolves to a light- and dark-appropriate value.
public enum LoritoColor {
    // Accent (indigo)
    public static let accent = Color.dynamic(light: Color(hex: 0x4F46E5), dark: Color(hex: 0x6366F1))
    public static let accentSoft = Color.dynamic(light: Color(hex: 0xEEF2FF), dark: Color(hex: 0x1E2540))
    public static let onAccentSoft = Color.dynamic(light: Color(hex: 0x4338CA), dark: Color(hex: 0xA5B4FC))
    public static let onAccent = Color.white

    // Surfaces
    public static let surface = Color.dynamic(light: Color(hex: 0xFCFCFD), dark: Color(hex: 0x0D1320))
    public static let surfaceSecondary = Color.dynamic(light: Color(hex: 0xF4F5FB), dark: Color(hex: 0x161E30))
    public static let separator = Color.dynamic(light: Color(hex: 0xE5E7EB), dark: Color(hex: 0x232C42))
    public static let segmentTrack = Color.dynamic(light: Color(hex: 0xDBDEF0), dark: Color(hex: 0x232C42))

    // Text
    public static let textPrimary = Color.dynamic(light: Color(hex: 0x0F172A), dark: Color(hex: 0xF1F5F9))
    public static let textSecondary = Color.dynamic(light: Color(hex: 0x6B7280), dark: Color(hex: 0x94A3B8))
    public static let textTertiary = Color.dynamic(light: Color(hex: 0x9CA3AF), dark: Color(hex: 0x64748B))

    // Status
    public static let success = Color.dynamic(light: Color(hex: 0x16A34A), dark: Color(hex: 0x4ADE80))
    public static let successSoft = Color.dynamic(light: Color(hex: 0xF0FDF4), dark: Color(hex: 0x13261A))
    public static let warning = Color.dynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xFBBF24))
    public static let warningSoft = Color.dynamic(light: Color(hex: 0xFFFBEB), dark: Color(hex: 0x2A2113))
    public static let danger = Color.dynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171))
    public static let dangerSoft = Color.dynamic(light: Color(hex: 0xFEF2F2), dark: Color(hex: 0x2A1416))

    // Info (used to distinguish a second accent in callouts)
    public static let info = Color.dynamic(light: Color(hex: 0x0EA5E9), dark: Color(hex: 0x38BDF8))
    public static let infoSoft = Color.dynamic(light: Color(hex: 0xECFEFF), dark: Color(hex: 0x10283A))
}
