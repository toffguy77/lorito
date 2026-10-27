import XCTest

/// Regression for 1.5.0: after the day's new card is graded, Today must show
/// the all-done state instead of offering another new card.
@MainActor
final class DailyNewCardLimitUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFinishingTheNewCardShowsAllDone() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        guard start.waitForExistence(timeout: 15) else { throw XCTSkip("no study work today on this simulator") }
        start.tap()

        // Reveal and grade every card in the session (default limit: one new card).
        let reveal = app.buttons["Показать ответ"]
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        var graded = 0
        while reveal.waitForExistence(timeout: 5) {
            reveal.tap()
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            graded += 1
            if graded > 60 { XCTFail("session did not end"); return }
        }
        XCTAssertTrue(app.staticTexts["¡Olé!"].waitForExistence(timeout: 10), "session summary not shown")
        app.buttons["Готово"].tap()

        XCTAssertTrue(app.staticTexts["Всё на сегодня!"].waitForExistence(timeout: 10),
                      "Today offered more cards after the day's new card was graded")
        XCTAssertFalse(app.buttons["Начать"].exists, "«Начать» still available")
    }
}
