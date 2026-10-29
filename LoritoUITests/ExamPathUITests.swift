import XCTest

/// exam-path-dele-ccse (+ lorito-pro gating): the free DELE A2 reading preview
/// runs to a result; the timer keeps running in the background; an attempt whose
/// time ran out while away is closed on launch; locked content opens the paywall
/// (sales on) or every form starts in full (sales off).
@MainActor
final class ExamPathUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func openDELE(_ app: XCUIApplication) {
        tabButton(app, "Каталог").tap()
        let exams = app.buttons["catalog.exams"]
        XCTAssertTrue(exams.waitForExistence(timeout: 15), "no exams entry in Catalog")
        exams.tap()
        let track = app.buttons["exams.track.dele-a2"]
        XCTAssertTrue(track.waitForExistence(timeout: 10))
        track.tap()
    }

    func testPreviewMockToResultAndTimerInBackground() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        openDELE(app)

        if salesEnabled {
            // Locked form → paywall, no attempt.
            app.buttons["exams.start.dele-a2.2"].tap()
            XCTAssertTrue(app.buttons["paywall.close"].waitForExistence(timeout: 10), "locked content did not open the paywall")
            app.buttons["paywall.close"].tap()
        }

        // Free preview (sales on) or the full form (sales off): reading comes first.
        let start = app.buttons["exams.start.dele-a2.1"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let timer = app.staticTexts["mock.timer"]
        XCTAssertTrue(timer.waitForExistence(timeout: 10))
        let before = timer.value as? String
        XCUIDevice.shared.press(.home)
        sleep(4)
        app.activate()
        XCTAssertTrue(timer.waitForExistence(timeout: 10))
        XCTAssertNotEqual(timer.value as? String, before, "timer paused in the background")

        app.buttons["Por las tardes"].tap()
        // Submit every section (one with the preview, four with the full form).
        let result = app.staticTexts["mock.result"]
        for _ in 0..<6 where !result.exists {
            let submit = app.buttons["mock.submit"]
            if submit.waitForExistence(timeout: 5) { submit.tap() }
        }
        XCTAssertTrue(result.waitForExistence(timeout: 10), "no result screen")
        app.buttons["mock.done"].tap()
    }

    func testExpiredAttemptClosedOnLaunch() throws {
        let app = XCUIApplication()
        launchSeeded(app, "-lorito-seed-expired-mock")
        dismissSystemAlerts(app)
        openDELE(app)
        let history = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'время вышло'")).firstMatch
        for _ in 0..<4 where !history.exists { app.swipeUp() }
        if !history.waitForExistence(timeout: 10) { print("[ui] dump:\n\(app.debugDescription)") }
        XCTAssertTrue(history.exists, "expired attempt not closed")
    }
}
