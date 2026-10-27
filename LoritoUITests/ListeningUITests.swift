import XCTest

/// listening-and-pronunciation: listen-choose hides the text until submission;
/// dictation checks the typed sentence. (Audio plays through the simulator voice.)
@MainActor
final class ListeningUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func openPractice(_ app: XCUIApplication, theme: String, card: String) {
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        tabButton(app, "Каталог").tap()
        XCTAssertTrue(app.staticTexts[theme].waitForExistence(timeout: 15))
        app.staticTexts[theme].tap()
        XCTAssertTrue(app.staticTexts[card].waitForExistence(timeout: 15))
        app.staticTexts[card].tap()
        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15))
        practice.tap()
    }

    func testListenChooseRevealsTextAfterAnswer() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-practice-types", "listen-choose"]
        openPractice(app, theme: "Существительное и его окружение", card: "Артикли")

        XCTAssertTrue(app.buttons["listen.play"].waitForExistence(timeout: 15), "no play button")
        XCTAssertTrue(app.buttons["listen.slow"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["listen.revealed"].exists, "audio text visible before answering")
        app.buttons["У меня проблема."].tap()
        app.buttons["Проверить"].tap()
        XCTAssertTrue(app.staticTexts["Верно"].waitForExistence(timeout: 10) || app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Верно'")).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["listen.revealed"].exists, "audio text not revealed after answering")
    }

    func testDictationChecksTypedSentence() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-practice-types", "dictation"]
        openPractice(app, theme: "Существительное и его окружение", card: "Прилагательные: согласование и позиция")

        XCTAssertTrue(app.buttons["listen.play"].waitForExistence(timeout: 15))
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("la casa es muy bonita")
        app.buttons["Проверить"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Верно'")).firstMatch.waitForExistence(timeout: 10),
                      "dictation not accepted")
        XCTAssertTrue(app.descendants(matching: .any)["listen.revealed"].exists)
    }
}
