import XCTest

/// study-goal + onboarding-full-setup: the DELE A2 preset in the onboarding goal
/// step shows a countdown on Today; no goal prompt after the first session;
/// removing the goal hides the card.
@MainActor
final class StudyGoalUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testGoalInOnboardingCountdownAndRemove() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        XCTAssertTrue(onboardingPastThemes(app), "goal step not after themes")
        let preset = app.buttons["goal.preset.deleA2"]
        XCTAssertTrue(preset.waitForExistence(timeout: 10))
        preset.tap()
        app.buttons["Далее"].tap()                                   // goal → variant
        skipRestOfOnboarding(app)
        dismissSystemAlerts(app)

        // Finish the first session (it opens right after onboarding).
        let reveal = app.buttons["Показать ответ"]
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        var graded = 0
        while reveal.waitForExistence(timeout: 8) {
            reveal.tap()
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            graded += 1
            if graded > 20 { XCTFail("session did not end"); return }
        }
        app.buttons["Готово"].tap()

        let exam = app.descendants(matching: .any)["today.goal.exam"]
        XCTAssertTrue(exam.waitForExistence(timeout: 10), "exam countdown not on Today")
        XCTAssertTrue(app.descendants(matching: .any)["today.goal.level"].exists, "level goal line missing")
        XCTAssertFalse(app.staticTexts["Есть дедлайн?"].exists, "goal prompt after onboarding")
        XCTAssertFalse(app.staticTexts["Где вы учите испанский?"].exists, "variant prompt after onboarding")

        // Remove both parts in Settings → «Цель».
        tabButton(app, "Настройки").tap()
        let goalRow = app.staticTexts["Цель"]
        XCTAssertTrue(goalRow.waitForExistence(timeout: 10))
        goalRow.tap()
        let removeLevel = app.buttons["goal.removeLevel"]
        for _ in 0..<4 where !removeLevel.exists { app.swipeUp() }
        removeLevel.tap()
        let removeExam = app.buttons["goal.removeExam"]
        for _ in 0..<4 where !removeExam.isHittable { app.swipeUp() }
        removeExam.tap()
        tabButton(app, "Сегодня").tap()
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["today.goal.exam"].exists, "goal card still shown")
    }
}
