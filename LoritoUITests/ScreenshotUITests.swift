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

/// Drives the practice-exercises flow end to end on the simulator against the
/// real bundled content: Catalog → card with exercises → Практика → answer →
/// check/feedback → continue.
@MainActor
final class PracticeFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func dismissSystemAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "Cancel", "Позже"] {
            let b = springboard.buttons[label]
            if b.waitForExistence(timeout: 2) { b.tap() }
        }
    }

    func testPracticeFlow() throws {
        let app = XCUIApplication()
        app.launch()
        dismissSystemAlertIfPresent()

        // Complete onboarding if this is a fresh install.
        if app.buttons["A1"].waitForExistence(timeout: 8) {
            app.buttons["A1"].tap()
            app.buttons["Далее"].tap()
            if app.buttons["Начать"].waitForExistence(timeout: 10) { app.buttons["Начать"].tap() }
        }
        dismissSystemAlertIfPresent()

        // Go to the Catalog.
        XCTAssertTrue(app.tabBars.buttons["Каталог"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Каталог"].tap()

        // A1 → theme "Существительное и его окружение".
        let theme = app.staticTexts["Существительное и его окружение"]
        XCTAssertTrue(theme.waitForExistence(timeout: 15), "noun theme row not found")
        theme.tap()

        // Open the card "Род существительных" (A1-07).
        let card = app.staticTexts["Род существительных"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "A1-07 card row not found")
        card.tap()

        // Tap the "Практика · N" button in the card reader.
        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15), "Практика button not found")
        practice.tap()

        // Exercise screen: answer, check, expect feedback, continue.
        let check = app.buttons["Проверить"]
        XCTAssertTrue(check.waitForExistence(timeout: 15), "exercise screen (Проверить) not shown")

        // Choose the first available multiple-choice option (article el/la etc.).
        for opt in ["la", "el", "una", "un", "los", "las"] {
            let b = app.buttons[opt]
            if b.exists { b.tap(); break }
        }
        XCTAssertTrue(check.isEnabled, "submit should be enabled after choosing an option")
        check.tap()

        // Feedback appears (Верно or Неверно), then continue.
        let verdict = app.staticTexts["Верно"].exists || app.staticTexts["Неверно"].exists
            || app.staticTexts["Верно"].waitForExistence(timeout: 5)
            || app.staticTexts["Неверно"].waitForExistence(timeout: 5)
        XCTAssertTrue(verdict, "no correct/incorrect feedback shown after checking")

        let cont = app.buttons["Продолжить"].exists ? app.buttons["Продолжить"] : app.buttons["Готово"]
        XCTAssertTrue(cont.waitForExistence(timeout: 5), "continue/done action not shown")
        cont.tap()

        // We either advanced to another exercise or reached the completion state.
        let advanced = app.buttons["Проверить"].waitForExistence(timeout: 5)
            || app.staticTexts["Готово!"].waitForExistence(timeout: 5)
        XCTAssertTrue(advanced, "did not advance to next exercise or completion")
    }
}
