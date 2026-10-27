import XCTest

/// weekly-recap-and-milestones: with last week's history and every A1 card in
/// long-term memory, Today shows the week's recap and "A1 закрыт" with sharing.
@MainActor
final class WeeklyRecapUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testRecapAndMilestoneOnToday() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-ui-testing", "-lorito-seed-recap"]
        app.launch()
        dismissSystemAlerts(app)

        XCTAssertTrue(app.descendants(matching: .any)["today.milestone"].waitForExistence(timeout: 30), "milestone not shown")
        XCTAssertTrue(app.staticTexts["A1 закрыт"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["today.recap"].exists, "recap not shown")
        XCTAssertTrue(app.buttons["Поделиться"].firstMatch.waitForExistence(timeout: 5), "share missing")
    }
}
