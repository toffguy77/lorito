import XCTest

/// Recall-first study flow: front without grades → reveal → grade → next card
/// on its front → … → session summary.
@MainActor
final class RecallFlowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func gradeButton(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    func testRecallFirstSessionToSummary() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        guard start.waitForExistence(timeout: 15) else {
            // Already studied today on this simulator: nothing to drive.
            throw XCTSkip("no study work today")
        }
        start.tap()

        let reveal = app.buttons["Показать ответ"]
        var graded = 0
        while reveal.waitForExistence(timeout: 10) {
            // Front side: no grade buttons until the answer is shown.
            XCTAssertFalse(gradeButton(app, "Хорошо").exists, "grade buttons visible on the front side")
            reveal.tap()

            let good = gradeButton(app, "Хорошо")
            XCTAssertTrue(good.waitForExistence(timeout: 10), "grade buttons not shown after reveal")
            // Interval preview reads in the label, e.g. "Хорошо, через 1 день".
            XCTAssertTrue(good.label.contains(","), "grade button has no interval caption: \(good.label)")
            good.tap()
            graded += 1
            if graded > 60 { XCTFail("session did not end"); return }
        }

        XCTAssertTrue(app.staticTexts["¡Olé!"].waitForExistence(timeout: 10), "session summary not shown")
        XCTAssertTrue(app.staticTexts["с первого раза"].exists)
        // Streak share card (rendered on device) is offered on the summary.
        XCTAssertTrue(app.buttons["Поделиться"].waitForExistence(timeout: 5), "share action missing")
        app.buttons["Готово"].tap()
        // Back on Today (the plan may top up new cards, so don't assume all-done).
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10), "did not return to Today")
        XCTAssertFalse(app.staticTexts["¡Olé!"].exists, "summary still shown")
    }
}
