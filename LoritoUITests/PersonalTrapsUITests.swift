import XCTest

/// personal-traps: an Опять creates «Мои ловушки» on Today; «Ясно» on two
/// different days resolves the trap.
@MainActor
final class PersonalTrapsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testAgainCreatesTrapEntry() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        XCTAssertFalse(app.buttons["today.traps"].exists)
        app.buttons["Начать"].tap()
        let reveal = app.buttons["Показать ответ"]
        var first = true
        var graded = 0
        while reveal.waitForExistence(timeout: 5) {
            reveal.tap()
            let title = first ? "Опять" : "Хорошо"
            let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10))
            button.tap()
            first = false
            graded += 1
            if graded > 20 { XCTFail("session did not end"); return }
        }
        XCTAssertTrue(app.buttons["summary.traps"].waitForExistence(timeout: 10), "summary has no traps link")
        app.buttons["Готово"].tap()
        XCTAssertTrue(app.buttons["today.traps"].waitForExistence(timeout: 10), "Today has no traps entry")
    }

    func testSecondClearResolvesTrap() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-ui-testing", "-lorito-seed-trap"]
        app.launch()
        dismissSystemAlerts(app)

        let entry = app.buttons["today.traps"]
        XCTAssertTrue(entry.waitForExistence(timeout: 30), "seeded trap not on Today")
        entry.tap()
        app.buttons["traps.start"].tap()
        let reveal = app.buttons["Показать раздел"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 10))
        reveal.tap()
        app.buttons["Ясно"].tap()
        XCTAssertTrue(app.buttons["На главную"].waitForExistence(timeout: 10))
        app.buttons["На главную"].tap()
        XCTAssertTrue(app.staticTexts["Ловушек нет. Они появляются, когда вы отвечаете «Опять» на карточку с частыми ошибками."]
            .waitForExistence(timeout: 10), "trap not resolved")
    }
}
