import XCTest

/// Drives the app through its main surfaces and captures App Store screenshots
/// via fastlane snapshot. Runs against a freshly reinstalled app (first-run
/// onboarding visible).
@MainActor
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testCaptureScreens() {
        let app = XCUIApplication()

        // 1 — Onboarding: choose a level.
        XCTAssertTrue(app.buttons["A1"].waitForExistence(timeout: 30))
        snapshot("01Onboarding")

        app.buttons["A2"].tap()
        app.buttons["Далее"].tap()

        // 2 — Onboarding: theme selection (all selected by default).
        XCTAssertTrue(app.buttons["Начать"].waitForExistence(timeout: 15))
        snapshot("02Themes")
        app.buttons["Начать"].tap()

        // 3 — Today screen.
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        snapshot("03Today")

        // 4 — Study session card.
        start.tap()
        XCTAssertTrue(app.buttons["Хорошо"].waitForExistence(timeout: 15))
        snapshot("04Study")
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // 5 — Catalog.
        if app.tabBars.buttons["Каталог"].waitForExistence(timeout: 10) {
            app.tabBars.buttons["Каталог"].tap()
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 10)
            snapshot("05Catalog")
        }
    }
}
