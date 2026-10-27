import XCTest

/// Verifies the Catalog tab resolves and navigates on both iPhone (bottom tab
/// bar) and iPad (top tab bar) — regression guard for the iPad screenshot gap
/// where `app.tabBars.buttons["Каталог"]` didn't match the iPad layout.
@MainActor
final class CatalogTabUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testCatalogTabNavigates() {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        let catalog = tabButton(app, "Каталог")
        XCTAssertTrue(catalog.waitForExistence(timeout: 15), "Catalog tab not found")
        catalog.tap()

        // Catalog-specific content (unambiguous, unlike the "A1" level header which
        // also appears as an onboarding button).
        XCTAssertTrue(
            app.staticTexts["Орфография и фонетика"].waitForExistence(timeout: 15),
            "Catalog content did not appear after tapping the Catalog tab"
        )
    }
}
