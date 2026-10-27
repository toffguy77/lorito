import XCTest

/// regional-variants: after the first session (and the goal prompt) Today asks
/// «Где вы учите испанский?»; choosing «Риоплатский» shows the `rio` block of a
/// card in place with «В Испании» as a note, and the drill asks vos.
@MainActor
final class RegionalVariantsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testVariantPromptChangesCardsAndDrill() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        closeFirstSessionIfOpen(app)

        // Finish the first session.
        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.tap()
        let reveal = app.buttons["Показать ответ"]
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        var graded = 0
        while reveal.waitForExistence(timeout: 5) {
            reveal.tap()
            XCTAssertTrue(good.waitForExistence(timeout: 10))
            good.tap()
            graded += 1
            if graded > 20 { XCTFail("session did not end"); return }
        }
        app.buttons["Готово"].tap()

        // One prompt per visit: the goal prompt first, the variant prompt on the next visit.
        XCTAssertTrue(app.staticTexts["Есть дедлайн?"].waitForExistence(timeout: 10), "goal prompt not shown")
        app.buttons["Не сейчас"].tap()
        XCTAssertFalse(app.staticTexts["Где вы учите испанский?"].exists, "two prompts in one visit")
        tabButton(app, "Каталог").tap()
        tabButton(app, "Сегодня").tap()
        XCTAssertTrue(app.staticTexts["Где вы учите испанский?"].waitForExistence(timeout: 10), "variant prompt not shown")
        let rio = app.buttons["today.prompt.rioplatense"]
        scrollToHittable(app, rio)
        rio.tap()
        XCTAssertFalse(app.staticTexts["Где вы учите испанский?"].waitForExistence(timeout: 2), "prompt still shown")

        // Settings reflect the choice.
        openSettingsTab(app)
        let picker = app.descendants(matching: .any)["spanishVariantPicker"]
        scrollToHittable(app, picker, maxSwipes: 12)
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Риоплатский'")).firstMatch.exists,
                      "variant not saved")

        // A card: the rio block in place, the Spain block as a note.
        tabButton(app, "Каталог").tap()
        // A1-14 «Личные местоимения» is in the theme «Глагол — ядро A1».
        let theme = app.staticTexts["Глагол — ядро A1"]
        XCTAssertTrue(theme.waitForExistence(timeout: 10), "theme not in the catalog")
        scrollToHittable(app, theme, maxSwipes: 8)
        theme.tap()
        let card = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Личные местоимения'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "card not in the theme")
        scrollToHittable(app, card, maxSwipes: 10)
        card.tap()
        let rioText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'В Аргентине и Уругвае'")).firstMatch
        scrollToHittable(app, rioText, maxSwipes: 10)
        XCTAssertTrue(rioText.exists, "rio block not shown in place")
        let note = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'В Испании'")).firstMatch
        XCTAssertTrue(note.exists, "«В Испании» note missing")
    }

    /// ser · futuro simple with the conjugation seed: Rioplatense never asks tú or vosotros.
    func testDrillAsksVosForRioplatense() throws {
        let app = XCUIApplication()
        launchSeeded(app, "-lorito-seed-conjugation")
        dismissSystemAlerts(app)
        openSettingsTab(app)
        let picker = app.descendants(matching: .any)["spanishVariantPicker"]
        scrollToHittable(app, picker, maxSwipes: 12)
        picker.tap()
        let option = app.buttons["Риоплатский"].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "no «Риоплатский» in the picker")
        option.tap()

        tabButton(app, "Сегодня").tap()
        let entry = app.buttons["today.conjugation"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15), "«Спряжения» not on Today")
        scrollToHittable(app, entry)
        entry.tap()
        let forms = ["yo": "seré", "vos": "serás", "él / ella / usted": "será", "nosotros": "seremos",
                     "ellos / ustedes": "serán"]
        let field0 = app.textFields["conj.field.0"], field1 = app.textFields["conj.field.1"]
        XCTAssertTrue(field0.waitForExistence(timeout: 10))
        for field in [field0, field1] {
            XCTAssertFalse(["tú", "vosotros"].contains(field.label), "Rioplatense drill asked \(field.label)")
            let form = try XCTUnwrap(forms[field.label], "unknown person \(field.label)")
            field.tap()
            field.typeText(form)
        }
        app.buttons["conj.check"].tap()
        XCTAssertTrue(app.staticTexts["Верно"].waitForExistence(timeout: 10))
    }
}
