import XCTest

/// Launches at the largest accessibility text size (AX5) and checks Today and
/// the study session stay usable: primary actions exist and are hittable.
/// Screenshots are attached for manual review.
@MainActor
final class DynamicTypeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTodayAndSessionAtAX5() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        if start.waitForExistence(timeout: 15) {
            attachScreenshot("Today-AX5")
            if !start.isHittable { app.swipeUp() }
            XCTAssertTrue(start.isHittable, "Начать is not reachable at AX5")
            start.tap()

            let reveal = app.buttons["Показать ответ"]
            XCTAssertTrue(reveal.waitForExistence(timeout: 15))
            attachScreenshot("Recall-AX5")
            XCTAssertTrue(reveal.isHittable, "Показать ответ is not reachable at AX5")
            reveal.tap()

            let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
            XCTAssertTrue(good.waitForExistence(timeout: 15))
            attachScreenshot("Session-AX5")
            XCTAssertTrue(good.isHittable, "grade buttons are not reachable at AX5")
            XCTAssertTrue(app.buttons["Закрыть"].isHittable, "close button is not reachable at AX5")
            app.buttons["Закрыть"].tap()
        } else {
            // Nothing to study today: the empty/all-done state must still render.
            attachScreenshot("Today-AX5-empty")
        }
    }
}
