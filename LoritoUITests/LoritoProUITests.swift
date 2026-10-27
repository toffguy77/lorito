import XCTest

/// lorito-pro: Settings → paywall with restore, close and Terms. Under
/// `xcodebuild test` the App Store isn't reachable (the scheme's StoreKit
/// configuration applies to Xcode Run only), so this exercises the unavailable
/// state; with products loaded (Xcode Run / sandbox) it also buys lifetime.
@MainActor
final class LoritoProUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPaywallFromSettings() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)

        tabButton(app, "Настройки").tap()
        let open = app.buttons["settings.pro.open"]
        for _ in 0..<4 where !open.exists { app.swipeUp() }
        XCTAssertTrue(open.waitForExistence(timeout: 10), "Pro entry missing")
        open.tap()

        XCTAssertTrue(app.buttons["paywall.restore"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["paywall.close"].exists)
        XCTAssertTrue(app.links["Условия использования"].exists || app.buttons["Условия использования"].exists)
        let buy = app.buttons["paywall.buy.com.toffguy.lorito.pro.lifetime"]
        let unavailable = app.staticTexts["paywall.unavailable"]
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline, !buy.exists, !unavailable.exists { usleep(250_000) }
        if unavailable.exists {
            // Store not reachable in this environment: the honest unavailable state, no buy button.
            XCTAssertFalse(app.buttons["paywall.buy.com.toffguy.lorito.pro.yearly"].exists)
            app.buttons["paywall.close"].tap()
            return
        }
        XCTAssertTrue(buy.exists && app.buttons["paywall.buy.com.toffguy.lorito.pro.yearly"].exists)
        buy.tap()
        // StoreKit's purchase confirmation sheet (local testing).
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Purchase", "Купить", "Subscribe", "Подписаться", "Confirm", "OK"] {
            let b = app.buttons[label].exists ? app.buttons[label] : springboard.buttons[label]
            if b.waitForExistence(timeout: 3) { b.tap(); break }
        }
        for label in ["OK", "ОК", "Done", "Готово"] {
            let b = springboard.buttons[label]
            if b.waitForExistence(timeout: 3) { b.tap(); break }
        }
        let status = app.staticTexts["settings.pro.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertEqual(status.label, "Lorito Pro активен")
    }
}
