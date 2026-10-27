import XCTest

/// Settings → «Помогать улучшать Lorito»: turning it off purges the queued
/// events and stops recording (UI-testing build exposes the queue size).
@MainActor
final class AnalyticsConsentUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testOptOutPurgesAndStopsRecording() {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)       // onboarding steps are recorded
        dismissSystemAlerts(app)

        tabButton(app, "Настройки").tap()
        let count = app.staticTexts["analytics.queueCount"]
        // The section sits below «Звук»; the list is lazy, so scroll to it.
        for _ in 0..<6 where !count.exists { app.swipeUp() }
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertNotEqual(count.label, "0", "onboarding events were not recorded")

        let toggle = app.switches["analyticsToggle"]
        XCTAssertEqual(toggle.value as? String, "1", "analytics should be on by default")
        toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertEqual(count.label, "0", "queue not purged on opt-out")

        // Something that would normally be recorded: open Today and come back.
        tabButton(app, "Сегодня").tap()
        tabButton(app, "Настройки").tap()
        for _ in 0..<6 where !count.exists { app.swipeUp() }
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertEqual(count.label, "0", "events recorded after opt-out")
    }
}
