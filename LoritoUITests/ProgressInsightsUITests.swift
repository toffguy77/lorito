import XCTest

/// Grade one card → Today's week strip marks today as studied, and the
/// progress heatmap shows a non-zero cell for today.
@MainActor
final class ProgressInsightsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testGradingMarksTodayInStripAndHeatmap() throws {
        let app = XCUIApplication()
        app.launch()
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        if start.waitForExistence(timeout: 15) {
            start.tap()
            let reveal = app.buttons["Показать ответ"]
            XCTAssertTrue(reveal.waitForExistence(timeout: 10))
            reveal.tap()
            let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            // Either the next card (close) or the summary (done) ends the session.
            if app.buttons["Закрыть"].waitForExistence(timeout: 5) {
                app.buttons["Закрыть"].tap()
            } else {
                app.buttons["Готово"].tap()
            }
        }

        let today = app.otherElements["weekStrip.today"].firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 10), "week strip not shown")
        XCTAssertEqual(today.value as? String, "занимались", "today not marked as studied")

        tabButton(app, "Прогресс").tap()
        let cell = app.otherElements["heatmap.today"].firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "heatmap not shown")
        XCTAssertNotEqual(cell.value as? String, "0", "today's heatmap cell is empty")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Progress"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
