import Testing
import CoreText
@testable import DesignSystem

@Suite("Bundled brand fonts", .serialized)
struct FontRegistryTests {
    static let postScriptNames = [
        "Unbounded-Bold", "Unbounded-ExtraBold",
        "Onest-Regular", "Onest-Medium", "Onest-SemiBold", "Onest-Bold",
        "InstrumentSerif-Regular", "InstrumentSerif-Italic",
    ]

    /// CoreText silently substitutes a fallback for unknown names, so compare
    /// the resolved font's PostScript name.
    private func resolves(_ name: String) -> Bool {
        let font = CTFontCreateWithName(name as CFString, 12, nil)
        return CTFontCopyPostScriptName(font) as String == name
    }

    @Test("Every PostScript name resolves after registration")
    func registered() {
        FontRegistry.registerAll()
        for name in Self.postScriptNames {
            #expect(resolves(name), "\(name) did not resolve")
            #expect(FontRegistry.isAvailable(name), "\(name) not reported available")
        }
    }

    @Test("Registering twice is harmless")
    func idempotent() {
        FontRegistry.registerAll()
        FontRegistry.registerAll()
        for name in Self.postScriptNames { #expect(resolves(name)) }
    }

    @Test("Bundle ships every font file")
    func bundled() {
        #expect(FontRegistry.fontURLs.count == Self.postScriptNames.count)
    }

    @Test("Unknown font is reported unavailable (fallback path)")
    func unknownUnavailable() {
        #expect(!FontRegistry.isAvailable("Lorito-DoesNotExist"))
    }
}
