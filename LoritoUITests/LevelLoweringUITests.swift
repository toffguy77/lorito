import XCTest

/// level-lowering-resets-progress: a B1 card graded «Опять» is due again today; after
/// lowering the level to A1 (confirmed) no B1 card comes back in the next session.
@MainActor
final class LevelLoweringUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testLoweringLevelResetsCardsAboveIt() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-placement-script", "A2=1,B1=0"]
        launchFresh(app)
        dismissSystemAlerts(app)

        // Placement proposes B1; the first session opens on a B1 card.
        let startTest = app.buttons["placement.start"]
        XCTAssertTrue(startTest.waitForExistence(timeout: 40))
        startTest.tap()
        let answer = app.buttons["Ответить"]
        while answer.waitForExistence(timeout: 5) { answer.tap() }
        app.buttons["Учить с B1"].tap()
        XCTAssertTrue(app.staticTexts["Что изучать"].waitForExistence(timeout: 10))
        app.buttons["Далее"].tap()
        skipRestOfOnboarding(app)
        dismissSystemAlerts(app)

        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 15), "first session did not open")
        XCTAssertTrue(chip(app, "B1").exists, "first card is not B1")
        reveal.tap()
        let again = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Опять'")).firstMatch
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        again.tap()                                                  // due again today
        app.buttons["Закрыть"].tap()
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10))

        // Settings: lowering to A1 asks first, then resets.
        openSettingsTab(app)
        let a1 = app.buttons["A1"]
        scrollToHittable(app, a1, maxSwipes: 12)
        a1.tap()
        let confirm = app.buttons["level.lower.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 10), "no confirmation before the reset")
        confirm.tap()

        // The next session holds no card above A1.
        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        guard start.waitForExistence(timeout: 15) else { return }  // nothing due: nothing above A1 either
        start.tap()
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        var graded = 0
        while reveal.waitForExistence(timeout: 5) {
            XCTAssertFalse(chip(app, "B1").exists || chip(app, "A2").exists, "a card above A1 is still planned")
            reveal.tap()
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            graded += 1
            if graded > 30 { XCTFail("session did not end"); return }
        }
    }

    private func chip(_ app: XCUIApplication, _ level: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "\(level) ·")).firstMatch
    }
}
