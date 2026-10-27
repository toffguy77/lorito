import XCTest

/// Regular-width (iPad) layouts: sidebar navigation, keyboard-only study, and
/// catalog selection surviving rotation. Skipped on iPhone.
@MainActor
final class iPadLayoutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad only") }
        XCUIDevice.shared.orientation = .landscapeLeft
        app = XCUIApplication()
        app.launch()
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testSidebarNavigation() {
        let catalog = tabButton(app, "Каталог")
        XCTAssertTrue(catalog.waitForExistence(timeout: 15))
        catalog.tap()
        XCTAssertTrue(app.staticTexts["Орфография и фонетика"].waitForExistence(timeout: 10))

        tabButton(app, "Прогресс").tap()
        XCTAssertTrue(app.otherElements["heatmap.today"].firstMatch.waitForExistence(timeout: 10))
        attach("iPad-Progress")

        tabButton(app, "Сегодня").tap()
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10))
        attach("iPad-Today")
    }

    func testKeyboardOnlySession() throws {
        tabButton(app, "Сегодня").tap()
        guard app.buttons["Начать"].waitForExistence(timeout: 15) else { throw XCTSkip("no study work today") }

        // Return → start. XCUITest's synthesized Return/Escape never reach the
        // app on the iPad simulator (no press events arrive), so fall back to
        // a tap; Return and Esc are verified manually with a hardware keyboard.
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        let reveal = app.buttons["Показать ответ"]
        if !reveal.waitForExistence(timeout: 3) { app.buttons["Начать"].tap() }
        XCTAssertTrue(reveal.waitForExistence(timeout: 10), "session did not start")
        let progress = app.otherElements["Прогресс сессии"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        let before = progress.value as? String
        XCTAssertTrue(before?.hasPrefix("0 из") == true, "unexpected progress \(before ?? "nil")")

        app.typeKey("3", modifierFlags: [])                                      // 3 on the front: nothing
        sleep(1)
        XCTAssertTrue(reveal.exists, "pressing 3 before reveal changed the card")
        XCTAssertEqual(progress.value as? String, before, "pressing 3 before reveal graded the card")
        attach("iPad-Recall")

        app.typeKey(XCUIKeyboardKey.space.rawValue, modifierFlags: [])           // Space → reveal
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        XCTAssertTrue(good.waitForExistence(timeout: 10), "Space did not reveal the answer")
        attach("iPad-Session")

        app.typeKey("3", modifierFlags: [])                                      // 3 → Хорошо
        let graded = NSPredicate { _, _ in
            (progress.exists && (progress.value as? String)?.hasPrefix("1 из") == true)
                || self.app.staticTexts["¡Olé!"].exists
        }
        expectation(for: graded, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
    }

    func testCatalogSelectionSurvivesRotation() {
        tabButton(app, "Каталог").tap()
        let theme = app.staticTexts["Существительное и его окружение"]
        XCTAssertTrue(theme.waitForExistence(timeout: 10))
        theme.tap()
        let cardRow = app.staticTexts["Род существительных"].firstMatch
        XCTAssertTrue(cardRow.waitForExistence(timeout: 10))
        cardRow.tap()
        // Reader shows the card; the card list stays visible beside it.
        XCTAssertTrue(app.buttons["Отложить карточку"].waitForExistence(timeout: 10)
                      || app.buttons["Вернуть в изучение"].exists, "reader not shown")
        attach("iPad-Catalog")

        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        XCTAssertTrue(app.staticTexts["Род существительных"].firstMatch.waitForExistence(timeout: 10),
                      "card selection lost on rotation")
        XCTAssertTrue(app.buttons["Отложить карточку"].exists || app.buttons["Вернуть в изучение"].exists,
                      "reader lost on rotation")
    }
}
