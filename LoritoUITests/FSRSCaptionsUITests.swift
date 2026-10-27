import XCTest

/// fsrs-scheduler: after reveal the grade buttons caption ordered intervals —
/// Опять ≤ Трудно ≤ Хорошо < Легко (a new card is far below the 365-day cap).
@MainActor
final class FSRSCaptionsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// Days from a spoken label like "Хорошо, через 2 дня", "Опять, сегодня", "Легко, через ≈ 3 мес.".
    private func days(_ label: String) -> Int? {
        if label.hasSuffix("сегодня") { return 0 }
        let digits = label.split(whereSeparator: { !$0.isNumber }).last.flatMap { Int($0) }
        guard let n = digits else { return nil }
        return label.contains("мес") ? n * 30 : n
    }

    func testGradeButtonsShowOrderedCaptions() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Сегодня").tap()
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 15), "no study session offered")
        start.tap()
        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 10))
        reveal.tap()

        var values: [Int] = []
        for title in ["Опять", "Трудно", "Хорошо", "Легко"] {
            let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10), "\(title) missing")
            let d = try XCTUnwrap(days(button.label), "no interval in \(button.label)")
            values.append(d)
        }
        XCTAssertEqual(values[0], 0, "Опять should read сегодня")
        XCTAssertLessThanOrEqual(values[0], values[1])
        XCTAssertLessThanOrEqual(values[1], values[2])
        XCTAssertLessThan(values[2], values[3], "Легко not longer than Хорошо: \(values)")
    }
}
