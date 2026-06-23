import Testing
@testable import Features

// Smoke test: the app's UI module and its layers import and link cleanly.
@Suite("Features smoke")
struct FeaturesTests {
    @Test("RootView constructs")
    @MainActor
    func rootViewConstructs() {
        _ = RootView()
    }
}
