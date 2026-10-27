import XCTest

/// Speaker button on the card front and «Произнести» in the long-press menu
/// of Spanish text. Needs a Spanish voice on the simulator (skips otherwise).
@MainActor
final class SpanishAudioUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSpeakerButtonAndLongPressMenu() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        XCTAssertTrue(app.buttons["Начать"].waitForExistence(timeout: 15))
        app.buttons["Начать"].tap()
        XCTAssertTrue(app.buttons["Показать ответ"].waitForExistence(timeout: 10))

        // The first A1 card's recall prompt contains Spanish (*h*, *v*, *y*).
        let speaker = app.buttons["Произнести"]
        guard speaker.waitForExistence(timeout: 5) else {
            throw XCTSkip("no Spanish voice on this simulator — speak affordances are hidden by design")
        }
        XCTAssertTrue(speaker.isHittable)
        speaker.tap()
        if app.buttons["Понятно"].waitForExistence(timeout: 3) { app.buttons["Понятно"].tap() }  // one-time silence hint

        // Long-press the Spanish part of the recall prompt → context menu with «Произнести».
        let prompt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Сколько букв'")).firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Произнести"].firstMatch.waitForExistence(timeout: 5), "no «Произнести» in the menu")
    }
}
