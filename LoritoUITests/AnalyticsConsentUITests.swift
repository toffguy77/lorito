import XCTest

/// Settings → «Помогать улучшать Lorito»: turning it off purges the queued
/// events and stops recording (UI-testing build exposes the queue size).
@MainActor
final class AnalyticsConsentUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// Tap the Settings tab until Settings shows (a tap during the first
    /// session's dismissal animation can be lost).
    private func openSettings(_ app: XCUIApplication) {
        for _ in 0..<4 {
            tabButton(app, "Настройки").tap()
            if app.switches["analyticsToggle"].waitForExistence(timeout: 3) { return }
        }
    }

    func testOptOutPurgesAndStopsRecording() {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)       // onboarding steps are recorded
        dismissSystemAlerts(app)

        openSettings(app)
        let count = app.staticTexts["analytics.queueCount"]
        // The section sits below «Звук»; the list is lazy, so scroll to it.
        for _ in 0..<6 where !count.exists { app.swipeUp() }
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertNotEqual(count.label, "0", "onboarding events were not recorded")

        let toggle = app.switches["analyticsToggle"]
        XCTAssertEqual(toggle.value as? String, "1", "analytics should be on by default")
        // Keep it clear of the floating tab bar, then tap the switch knob area.
        app.swipeUp()
        for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertEqual(count.label, "0", "queue not purged on opt-out")

        // Something that would normally be recorded: open Today and come back.
        tabButton(app, "Сегодня").tap()
        openSettings(app)
        for _ in 0..<6 where !count.exists { app.swipeUp() }
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertEqual(count.label, "0", "events recorded after opt-out")
    }
}
