import XCTest

/// Regression for 1.5.0: after the day's new card is graded, Today must show
/// the all-done state instead of offering another new card.
@MainActor
final class DailyNewCardLimitUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFinishingTheNewCardShowsAllDone() throws {
        let app = XCUIApplication()
        app.launch()
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        guard start.waitForExistence(timeout: 15) else { throw XCTSkip("no study work today on this simulator") }
        start.tap()

        // Grade every card in the session (default limit: one new card).
        var graded = 0
        while app.buttons["Хорошо"].waitForExistence(timeout: 5) {
            app.buttons["Хорошо"].tap()
            graded += 1
            if graded > 60 { XCTFail("session did not end"); return }
        }
        XCTAssertTrue(app.staticTexts["Готово!"].waitForExistence(timeout: 10), "completion state not shown")
        app.buttons["На главную"].tap()

        XCTAssertTrue(app.staticTexts["Всё на сегодня!"].waitForExistence(timeout: 10),
                      "Today offered more cards after the day's new card was graded")
        XCTAssertFalse(app.buttons["Начать"].exists, "«Начать» still available")
    }
}
