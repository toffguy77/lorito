import Testing
@testable import Features

@Suite("About / Licenses")
struct AboutTests {
    @Test("Credits list is non-empty and includes the OpenMoji CC BY-SA attribution")
    func creditsIncludeOpenMoji() {
        let entries = LicenseEntry.all
        #expect(!entries.isEmpty)
        let openmoji = entries.first { $0.name == "OpenMoji" }
        #expect(openmoji != nil, "OpenMoji attribution missing")
        #expect(openmoji?.license == "CC BY-SA 4.0")
        #expect(openmoji?.url.contains("openmoji.org") == true)
        // Every entry carries name, license, and source.
        for e in entries {
            #expect(!e.name.isEmpty)
            #expect(!e.license.isEmpty)
            #expect(!e.url.isEmpty)
        }
    }
}
