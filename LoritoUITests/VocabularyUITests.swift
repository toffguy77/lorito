import XCTest

/// vocabulary-decks: enable words → recognition; production with a wrong
/// article; «В мои слова» from a card; delete a personal word.
@MainActor
final class VocabularyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func openSettings(_ app: XCUIApplication) { openSettingsTab(app) }

    func testEnableWordsAndLearnInRecognition() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        openSettings(app)
        let toggle = app.switches["wordsToggle"]
        scrollToHittable(app, toggle, maxSwipes: 12)
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        if (toggle.value as? String) != "1" { toggle.switches.firstMatch.tap() }
        XCTAssertEqual(toggle.value as? String, "1", "words not enabled")
        tabButton(app, "Сегодня").tap()
        let words = app.buttons["today.words"]
        _ = words.waitForExistence(timeout: 5)
        scrollToHittable(app, words)
        XCTAssertTrue(words.exists, "no «Слова» on Today")
        words.tap()
        XCTAssertTrue(app.buttons["words.reveal"].waitForExistence(timeout: 10), "not in recognition mode")
        app.buttons["words.reveal"].tap()
        XCTAssertTrue(app.staticTexts["words.translation"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch.tap()
    }

    func testProductionReportsWrongArticle() throws {
        let app = XCUIApplication()
        launchSeeded(app, "-lorito-seed-words-production")
        dismissSystemAlerts(app)
        let words = app.buttons["today.words"]
        _ = words.waitForExistence(timeout: 15)
        scrollToHittable(app, words)
        XCTAssertTrue(words.exists)
        words.tap()
        let field = app.textFields["words.answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "not in production mode")
        field.tap()
        field.typeText("el casa")
        app.buttons["words.check"].tap()
        let feedback = app.staticTexts["words.feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains("роде"), feedback.label)
    }

    func testSaveFromCardAndDeletePersonalWord() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        app.buttons["Начать"].tap()
        XCTAssertTrue(app.buttons["Показать ответ"].waitForExistence(timeout: 10))
        let prompt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Сколько букв'")).firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.press(forDuration: 1.2)
        let save = app.buttons["В мои слова"].firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 5), "no «В мои слова» in the menu")
        save.tap()
        let ru = app.textFields["words.unknown.ru"]
        if ru.waitForExistence(timeout: 3) {
            ru.tap()
            ru.typeText("перевод")
            app.buttons["words.unknown.save"].tap()
        }
        app.buttons["Закрыть"].firstMatch.tap()

        openSettings(app)
        let decks = app.buttons["words.decks"]
        scrollToHittable(app, decks, maxSwipes: 12)
        decks.tap()
        let entry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'words.personal.'")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "saved word not in «Мои слова»")
        entry.press(forDuration: 1.2)
        let delete = app.buttons["Удалить"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "no delete action")
        delete.tap()
        XCTAssertFalse(entry.waitForExistence(timeout: 3), "personal word not deleted")
    }
}
