import XCTest

/// App Store app preview (app-store-presence): a paced walk through the demo store,
/// recorded with `simctl io recordVideo` by `tools/record_app_preview.sh`, which cuts
/// the recording at the printed marks. Runs only when that script asks for it
/// (`TEST_RUNNER_LORITO_PREVIEW=1`), so the regular UI suite skips it.
@MainActor
final class AppPreviewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        guard ProcessInfo.processInfo.environment["LORITO_PREVIEW"] == "1" else {
            throw XCTSkip("app preview recording only")
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
    }

    /// Prints a scene mark with the wall-clock time; the script maps it onto the video.
    private func mark(_ name: String) {
        print(String(format: "[preview] %@ %.3f", name, Date().timeIntervalSince1970))
    }

    private func hold(_ seconds: Double) { usleep(useconds_t(seconds * 1_000_000)) }

    func testPreviewWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments += ["-lorito-demo-data"]
        launchFresh(app)
        dismissSystemAlerts(app)

        // Today: the plan, goal countdown, trainers.
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 30))
        hold(1)
        mark("today")
        hold(2.5)

        // Recall first, then the rule and its common mistakes.
        start.tap()
        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 15))
        mark("recall")
        hold(2.5)
        reveal.tap()
        let good = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch
        XCTAssertTrue(good.waitForExistence(timeout: 15))
        mark("rule")
        hold(1.5)
        let mistakes = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Частые ошибки'")).firstMatch
        for _ in 0..<8 where !(mistakes.exists && mistakes.isHittable) {
            app.swipeUp(velocity: .slow)
        }
        mark("mistakes")
        hold(2.5)
        good.tap()
        hold(1)
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // Conjugation trainer.
        let conjugation = app.buttons["today.conjugation"]
        scrollToHittable(app, conjugation)
        XCTAssertTrue(conjugation.waitForExistence(timeout: 15))
        conjugation.tap()
        XCTAssertTrue(app.buttons["conj.check"].waitForExistence(timeout: 15))
        mark("conjugation")
        hold(2.5)
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // Progress.
        tabButton(app, "Прогресс").tap()
        _ = app.otherElements["heatmap.today"].firstMatch.waitForExistence(timeout: 10)
        mark("progress")
        hold(2.5)

        // Exams.
        tabButton(app, "Каталог").tap()
        let exams = app.buttons["catalog.exams"]
        scrollToHittable(app, exams)
        XCTAssertTrue(exams.waitForExistence(timeout: 15))
        exams.tap()
        let dele = app.buttons["exams.track.dele-a2"]
        XCTAssertTrue(dele.waitForExistence(timeout: 10))
        mark("exams")
        hold(1.5)
        dele.tap()
        hold(2.5)
        mark("end")
    }
}
