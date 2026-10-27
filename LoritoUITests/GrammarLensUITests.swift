import XCTest

/// grammar-lens: paste «Espero que vengas» → highlight → open the card → add it
/// to review → it is the first card of today's session.
@MainActor
final class GrammarLensUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPasteHighlightOpenCardAndRequest() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        closeFirstSessionIfOpen(app)

        tabButton(app, "Сегодня").tap()
        let entry = app.buttons["today.lens"]
        _ = entry.waitForExistence(timeout: 10)
        scrollToHittable(app, entry, maxSwipes: 10)
        entry.tap()

        let field = app.textViews["lens.text"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "no text field")
        field.tap()
        field.typeText("Espero que vengas mañana.")
        app.buttons["lens.analyze"].tap()

        let highlight = app.descendants(matching: .any)["lens.highlight.0"]
        XCTAssertTrue(highlight.waitForExistence(timeout: 10), "no highlight")
        XCTAssertTrue(app.staticTexts["Espero que vengas"].exists, "span not shown")

        // Open the card, come back, add it to review.
        let card = app.descendants(matching: .any)["lens.card.B1-02"]
        scrollToHittable(app, card)
        card.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'желание и влияние'")).firstMatch
            .waitForExistence(timeout: 10), "card reader not opened")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let request = app.buttons["lens.request.B1-02"]
        XCTAssertTrue(request.waitForExistence(timeout: 10))
        scrollToHittable(app, request)
        request.tap()
        XCTAssertTrue(app.descendants(matching: .any)["lens.status.B1-02"].waitForExistence(timeout: 5), "status not updated")
        app.buttons["Готово"].firstMatch.tap()

        // Today's session starts with the requested card.
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.staticTexts["Subjuntivo: желание и влияние"].waitForExistence(timeout: 10),
                      "requested card is not first")
    }
}
