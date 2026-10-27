import XCTest

/// conjugation-trainer: with the futuro-simple card studied and the trainer on,
/// Today offers «Спряжения»; two persons are asked; an answer without accents is
/// «почти» with the accented form; the item leaves today's list once graded.
@MainActor
final class ConjugationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// ser · futuro simple, by person label.
    let forms = ["yo": "seré", "tú": "serás", "él / ella / usted": "será",
                 "nosotros": "seremos", "vosotros": "seréis", "ellos / ustedes": "serán"]

    func testDrillChecksAccentsAndReschedules() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-ui-testing", "-lorito-seed-conjugation"]
        app.launch()
        dismissSystemAlerts(app)

        let entry = app.buttons["today.conjugation"]
        XCTAssertTrue(entry.waitForExistence(timeout: 30), "«Спряжения» not on Today")
        XCTAssertTrue(entry.label.contains("Спряжения · 1"), entry.label)
        entry.tap()

        let field0 = app.textFields["conj.field.0"], field1 = app.textFields["conj.field.1"]
        XCTAssertTrue(field0.waitForExistence(timeout: 10))
        let p0 = try XCTUnwrap(forms[field0.label], "unknown person \(field0.label)")
        let p1 = try XCTUnwrap(forms[field1.label], "unknown person \(field1.label)")
        field0.tap()
        field0.typeText(p0)
        field1.tap()
        let plain = p1.folding(options: .diacriticInsensitive, locale: nil)
        field1.typeText(plain)
        app.buttons["conj.check"].tap()

        XCTAssertTrue(app.staticTexts["Верно"].waitForExistence(timeout: 10), "first answer not correct")
        if plain != p1 {
            XCTAssertTrue(app.staticTexts["Почти"].exists, "missing accent not reported as «почти»")
            XCTAssertTrue(app.staticTexts[p1].exists, "accented form \(p1) not shown")
        }

        app.buttons["conj.next"].tap()
        XCTAssertTrue(app.buttons["На главную"].waitForExistence(timeout: 10))
        app.buttons["На главную"].tap()
        XCTAssertTrue(app.staticTexts["¡Hola!"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["today.conjugation"].exists, "graded item still planned today")
    }
}
