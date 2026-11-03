import XCTest

/// practice-hub: «Практика» on Today explains the empty state for a fresh user;
/// with a studied card, mixed practice and level practice from the Catalog start
/// sessions of that card's exercises only.
@MainActor
final class PracticeHubUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFreshUserSeesExplainedEmptyState() {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        let entry = app.buttons["today.practice"]
        XCTAssertTrue(scrollTo(entry, in: app), "«Практика» not on Today")
        entry.tap()
        let mixed = app.buttons["practice.mode.mixed"]
        XCTAssertTrue(mixed.waitForExistence(timeout: 10))
        XCTAssertTrue(mixed.label.contains("доступно 0 из"), mixed.label)
        mixed.tap()
        let alert = app.alerts["Пока нечего тренировать"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "empty state not explained")
        alert.buttons["Понятно"].tap()
    }

    func testStudiedCardFeedsMixedAndLevelPractice() {
        let app = XCUIApplication()
        launchSeeded(app, "-lorito-seed-conjugation")      // A2-07 studied (5 exercises)
        dismissSystemAlerts(app)

        let entry = app.buttons["today.practice"]
        XCTAssertTrue(scrollTo(entry, in: app), "«Практика» not on Today")
        entry.tap()
        let mixed = app.buttons["practice.mode.mixed"]
        XCTAssertTrue(mixed.waitForExistence(timeout: 10))
        XCTAssertTrue(mixed.label.contains("доступно 5 из"), mixed.label)
        mixed.tap()
        XCTAssertTrue(app.staticTexts["A2 · A2-07"].waitForExistence(timeout: 10), "session did not start on A2-07")
        app.buttons["Закрыть"].firstMatch.tap()
        app.buttons["Готово"].firstMatch.tap()

        let catalog = tabButton(app, "Каталог")
        if !catalog.waitForExistence(timeout: 15) { print("[ui-debug]\n\(app.debugDescription)") }
        XCTAssertTrue(catalog.exists)
        catalog.tap()
        let a2 = app.buttons["Уровень A2"].firstMatch
        XCTAssertTrue(a2.waitForExistence(timeout: 10))
        a2.tap()
        let level = app.buttons["catalog.practice.level"]
        XCTAssertTrue(level.waitForExistence(timeout: 10), "«Практика по уровню» not in the Catalog")
        XCTAssertTrue(level.label.contains("доступно 5 из"), level.label)
        level.tap()
        XCTAssertTrue(app.staticTexts["A2 · A2-07"].waitForExistence(timeout: 10), "level session did not start")
        app.buttons["Закрыть"].firstMatch.tap()
    }

    /// Scroll Today until `element` is hittable.
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.waitForExistence(timeout: 30) else { return false }
        var tries = 0
        while !element.isHittable, tries < 8 {
            app.swipeUp()
            tries += 1
        }
        if !element.isHittable { print("[ui-debug]\n\(app.debugDescription)") }
        return element.isHittable
    }
}
