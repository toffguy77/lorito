import XCTest

/// placement-test-and-first-session: the test path proposes a level and the
/// first session opens right after onboarding; the manual path still works and
/// a relaunch lands on Today.
@MainActor
final class PlacementUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPlacementProposesB1AndFirstSessionOpensWithThreeNewCards() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-placement-script", "A2=1,B1=0"]
        launchFresh(app)
        dismissSystemAlerts(app)

        // Level step: level list first, then the test entry.
        XCTAssertTrue(app.buttons["A1"].waitForExistence(timeout: 40), "level step not first")
        let startTest = app.buttons["placement.start"]
        XCTAssertTrue(startTest.exists)
        startTest.tap()

        // A2 block (3) passes, B1 block (3) fails → 6 questions.
        let answer = app.buttons["Ответить"]
        var asked = 0
        while answer.waitForExistence(timeout: 5) {
            answer.tap()
            asked += 1
            if asked > 20 { XCTFail("placement did not end"); return }
        }
        XCTAssertEqual(asked, 6)
        let proposed = app.staticTexts["placement.proposed"]
        XCTAssertTrue(proposed.waitForExistence(timeout: 5))
        XCTAssertEqual(proposed.label, "B1")
        app.buttons["Учить с B1"].tap()

        // Themes second, reminders last.
        XCTAssertTrue(app.staticTexts["Что изучать"].waitForExistence(timeout: 10), "themes not second")
        app.buttons["Далее"].tap()
        XCTAssertTrue(app.staticTexts["Напоминания"].waitForExistence(timeout: 10), "reminders not last")
        app.buttons["Пропустить"].tap()
        dismissSystemAlerts(app)

        // The session opens on its first card — a B1 card — and holds 3 new cards.
        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 15), "first session did not open")
        let chip = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'B1'")).firstMatch
        XCTAssertTrue(chip.exists, "first card is not B1")
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        var graded = 0
        while reveal.waitForExistence(timeout: 5) {
            reveal.tap()
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            graded += 1
            if graded > 20 { XCTFail("session did not end"); return }
        }
        XCTAssertEqual(graded, 3, "first session should hold 3 new cards")
    }

    func testManualPathCompletesAndRelaunchLandsOnToday() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)   // manual A1; closes the auto-opened first session
        dismissSystemAlerts(app)
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10), "not on Today after onboarding")

        // UI-testing launches always start from a fresh store, so a cold relaunch
        // can't be observed here; background → foreground must not reopen the
        // session (the auto-start is a one-off in-memory flag, consumed above).
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10), "relaunch did not land on Today")
        XCTAssertFalse(app.buttons["Показать ответ"].exists, "a session auto-started again")
    }
}
