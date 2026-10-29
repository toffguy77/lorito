import XCTest

/// onboarding-full-setup: Settings «Пройти настройку заново» opens the onboarding
/// prefilled; a pace change saved in it shows in Settings after closing.
@MainActor
final class OnboardingSetupUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSetupAgainFromSettings() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        openSettingsTab(app)
        let again = app.buttons["settings.setupAgain"]
        scrollToHittable(app, again)
        XCTAssertTrue(again.waitForExistence(timeout: 10), "no «Пройти настройку заново»")
        again.tap()

        // Prefilled: the level is chosen, so «Далее» is enabled right away.
        XCTAssertTrue(app.staticTexts["Ваш уровень"].waitForExistence(timeout: 10))
        let next = app.buttons["Далее"]
        XCTAssertTrue(next.isEnabled, "level not prefilled")
        next.tap()                                                   // level → themes
        XCTAssertTrue(app.staticTexts["Что изучать"].waitForExistence(timeout: 10))
        app.buttons["Далее"].tap()                                   // themes → goal
        XCTAssertTrue(app.staticTexts["Цель"].waitForExistence(timeout: 10))
        app.buttons["Пропустить"].tap()                              // goal
        XCTAssertTrue(app.staticTexts["Какой испанский"].waitForExistence(timeout: 10))
        app.buttons["Пропустить"].tap()                              // variant

        // Pace: one more new card per day, saved on «Далее».
        let cards = app.steppers["onboarding.cards"]
        XCTAssertTrue(cards.waitForExistence(timeout: 10), "pace step missing")
        cards.buttons.element(boundBy: 1).tap()
        app.buttons["Далее"].tap()                                   // pace → sound
        XCTAssertTrue(app.staticTexts["Звук"].waitForExistence(timeout: 10))
        app.buttons["onboarding.close"].tap()

        let pace = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Новых карточек в день: 2'")).firstMatch
        scrollToHittable(app, pace, maxSwipes: 12)
        XCTAssertTrue(pace.waitForExistence(timeout: 10), "pace from the setup not in Settings")
    }

    /// setup-close-discards-unsaved-scope: picking B1 in a re-run and closing at the
    /// level step leaves A1 stored and shown in Settings.
    func testClosingSetupDiscardsUnsavedLevel() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)                             // A1
        dismissSystemAlerts(app)

        openSettingsTab(app)
        let again = app.buttons["settings.setupAgain"]
        scrollToHittable(app, again)
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        again.tap()
        XCTAssertTrue(app.staticTexts["Ваш уровень"].waitForExistence(timeout: 10))
        app.buttons["B1"].tap()
        app.buttons["onboarding.close"].tap()

        let b1 = app.buttons["B1"]
        scrollToHittable(app, b1, maxSwipes: 12)
        XCTAssertTrue(b1.waitForExistence(timeout: 10))
        XCTAssertFalse(b1.isSelected, "Settings shows the unsaved B1")
        XCTAssertTrue(app.buttons["A1"].isSelected)
    }
}
