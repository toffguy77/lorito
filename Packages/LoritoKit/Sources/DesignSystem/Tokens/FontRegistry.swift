import Foundation
import CoreText

/// Registers the bundled brand fonts (Unbounded, Onest, Instrument Serif) from
/// the module bundle. SPM resources live in `Bundle.module`, which `UIAppFonts`
/// cannot see, so registration happens in code at app start.
public enum FontRegistry {
    /// Every bundled font file.
    public static var fontURLs: [URL] {
        let ttf = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        let otf = Bundle.module.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? []
        return ttf + otf
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var didRegister = false
    nonisolated(unsafe) private static var availability: [String: Bool] = [:]

    /// Register every bundled font for the process. Idempotent: repeated calls
    /// are no-ops and an "already registered" result is not an error.
    public static func registerAll() {
        lock.lock(); defer { lock.unlock() }
        guard !didRegister else { return }
        didRegister = true
        for url in fontURLs {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error),
               let cfError = error?.takeRetainedValue(),
               CFErrorGetCode(cfError) != CTFontManagerError.alreadyRegistered.rawValue {
                // Non-fatal: styles fall back to the system font.
                #if DEBUG
                print("FontRegistry: failed to register \(url.lastPathComponent): \(cfError)")
                #endif
            }
        }
    }

    /// Whether `postScriptName` resolves to an installed font (registering the
    /// bundle first). CoreText substitutes a fallback for unknown names, so the
    /// resolved name is compared.
    public static func isAvailable(_ postScriptName: String) -> Bool {
        registerAll()
        lock.lock(); defer { lock.unlock() }
        if let cached = availability[postScriptName] { return cached }
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        let available = CTFontCopyPostScriptName(font) as String == postScriptName
        availability[postScriptName] = available
        return available
    }
}
