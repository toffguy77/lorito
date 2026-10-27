import XCTest

/// streak-protection: a missed day covered by a freeze keeps the streak and
/// Today says «Серия спасена заморозкой».
@MainActor
final class StreakProtectionUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFrozenDayKeepsStreakAndShowsBanner() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-ui-testing", "-lorito-seed-frozen-yesterday"]
        app.launch()
        dismissSystemAlerts(app)

        let banner = app.descendants(matching: .any)["today.streakBanner"]
        if !banner.waitForExistence(timeout: 30) { print("[ui] dump:\n\(app.debugDescription)") }
        XCTAssertTrue(banner.exists, "freeze banner not on Today")
        XCTAssertTrue(banner.label.contains("Серия спасена заморозкой"), banner.label)

        tabButton(app, "Прогресс").tap()
        let streak = app.descendants(matching: .any)["stats.streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 10))
        XCTAssertTrue(streak.label.contains("Текущая серия: 10"), streak.label)
        XCTAssertTrue(streak.label.contains("заморозки: 0 из 2"), streak.label)
    }
}
