import XCTest

// MARK: - Shared UI helpers

/// Launch with a fresh in-memory store and first-run onboarding, so every UI
/// test starts from the same state regardless of order or earlier runs.
@MainActor
func launchFresh(_ app: XCUIApplication) {
    app.launchArguments += ["-lorito-ui-testing"]
    app.launch()
    // The first launch of a full run has been seen to come up in normal mode
    // (persistent store, onboarding done). A fresh UI-testing launch always
    // starts on onboarding — unless demo data is seeded — so relaunch once.
    guard !app.launchArguments.contains("-lorito-demo-data") else { return }
    let deadline = Date().addingTimeInterval(40)
    while Date() < deadline, !app.buttons["A1"].exists, !tabButton(app, "Сегодня").exists { usleep(250_000) }
    if !app.buttons["A1"].exists, tabButton(app, "Сегодня").exists {
        print("[ui] launch came up without UI-testing state — relaunching")
        app.terminate()
        app.launch()
    }
}

/// Launch with a UI-testing seed (`-lorito-seed-…`); relaunch once if the launch
/// came up without UI-testing state (seen on the first launch of a run).
@MainActor
func launchSeeded(_ app: XCUIApplication, _ seed: String) {
    app.launchArguments += ["-lorito-ui-testing", seed]
    app.launch()
    let marker = app.descendants(matching: .any)["ui-testing-mode"]
    if !marker.waitForExistence(timeout: 20) {
        print("[ui] seeded launch came up without UI-testing state — relaunching")
        app.terminate()
        app.launch()
        _ = marker.waitForExistence(timeout: 20)
    }
}

/// Dismiss any system alert (notification permission, etc.) that may block the UI.
@MainActor
func dismissSystemAlerts(_ app: XCUIApplication) {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    for label in ["Allow", "Разрешить", "Not Now", "Позже", "Cancel", "Don't Allow", "Не разрешать"] {
        let b = springboard.buttons[label]
        if b.waitForExistence(timeout: 2) { b.tap() }
    }
}

/// Complete first-run onboarding (level → themes → skip reminders) when present.
/// Mirrors the current three-step flow so downstream tests reach the main app.
@MainActor
func completeOnboardingIfPresent(_ app: XCUIApplication, level: String = "A1") {
    // A cold first launch can take well over 8 s: wait for onboarding or the
    // main app, whichever shows first, instead of silently skipping onboarding.
    let deadline = Date().addingTimeInterval(40)
    while Date() < deadline, !app.buttons[level].exists, !tabButton(app, "Сегодня").exists {
        usleep(250_000)
    }
    guard app.buttons[level].exists else {
        if !tabButton(app, "Сегодня").exists { print("[ui] onboarding not found:\n\(app.debugDescription)") }
        return
    }
    app.buttons[level].tap()
    app.buttons["Далее"].tap()                                   // level → themes
    if app.staticTexts["Что изучать"].waitForExistence(timeout: 10) {
        app.buttons["Далее"].tap()                               // themes → reminders
    }
    if app.buttons["Пропустить"].waitForExistence(timeout: 10) {
        app.buttons["Пропустить"].tap()                          // skip the reminder step
    }
    closeFirstSessionIfOpen(app)
}

/// Onboarding opens the first study session directly (placement-test); close it
/// so tests start from Today.
@MainActor
func closeFirstSessionIfOpen(_ app: XCUIApplication) {
    // Wait for the session itself: on iPad the sidebar's «Сегодня» stays in the
    // hierarchy behind the session cover, so it can't end the wait.
    // A cover that appears late is caught by the second pass.
    for timeout in [8.0, 2.0] {
        guard app.buttons["Показать ответ"].waitForExistence(timeout: timeout) else { continue }
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }
        _ = app.staticTexts["¡Hola!"].waitForExistence(timeout: 5)
    }
}

/// Resolve a tab by label. On iPhone the floating tab bar exposes each
/// destination as a `Button`; on iPad (sidebar-adaptable tab view) the sidebar
/// exposes them as cells. Match either by label.
@MainActor
func tabButton(_ app: XCUIApplication, _ label: String) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(
        format: "label == %@ AND (elementType == %d OR elementType == %d)",
        label, XCUIElement.ElementType.button.rawValue, XCUIElement.ElementType.cell.rawValue
    )).firstMatch
}

/// Poll a query until it reports at least `n` matches (or timeout).
@MainActor
func waitForCount(_ query: XCUIElementQuery, atLeast n: Int, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if query.count >= n { return true }
        usleep(200_000)
    }
    return query.count >= n
}

/// App Store screenshots (app-store-presence): six scenes per device class from
/// a seeded demo store (`-lorito-demo-data`) so every screen is full and
/// deterministic — Today plan, recall front, revealed card with «Частые ошибки»,
/// exercise, progress, catalog. Headlines are added by `tools/frame_screenshots.swift`.
@MainActor
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        // iPad App Store screenshots are taken in landscape (sidebar layouts).
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-lorito-demo-data"]
        launchFresh(app)
    }

    func testCaptureScreens() {
        let app = XCUIApplication()
        dismissSystemAlerts(app)

        // 1 — Today: the day's plan (demo reviews due + new cards, streak).
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Today plan not shown")
        snapshot("01Today")

        // 2 — Recall-first card front.
        start.tap()
        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 15))
        snapshot("02Recall")

        // 3 — Revealed card scrolled to its «Частые ошибки» section.
        reveal.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch.waitForExistence(timeout: 15))
        let mistakes = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Частые ошибки'")).firstMatch
        for _ in 0..<8 where !(mistakes.exists && mistakes.isHittable) { app.swipeUp() }
        snapshot("03Mistakes")
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // 5 — Progress: streak, heatmap, long-term memory.
        let progress = tabButton(app, "Прогресс")
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        progress.tap()
        _ = app.otherElements["heatmap.today"].firstMatch.waitForExistence(timeout: 10)
        snapshot("05Progress")

        // 6 — Catalog.
        let catalog = tabButton(app, "Каталог")
        XCTAssertTrue(catalog.waitForExistence(timeout: 10))
        catalog.tap()
        _ = app.staticTexts["A1"].waitForExistence(timeout: 10)
        snapshot("06Catalog")

        // 4 — Exercise on «Род существительных» (A1-07), an option chosen and checked.
        let theme = app.staticTexts["Существительное и его окружение"]
        XCTAssertTrue(theme.waitForExistence(timeout: 15), "noun theme row not found")
        theme.tap()
        let card = app.staticTexts["Род существительных"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "A1-07 card row not found")
        card.tap()
        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15), "Практика button not found")
        practice.tap()
        XCTAssertTrue(app.buttons["Проверить"].waitForExistence(timeout: 15), "exercise screen not shown")
        snapshot("04Exercise")
    }
}

/// Drives the practice-exercises flow end to end on the simulator against the
/// real bundled content: Catalog → card with exercises → Практика → answer →
/// check/feedback → continue.
@MainActor
final class PracticeFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func dismissSystemAlertIfPresent() {
        dismissSystemAlerts(XCUIApplication())
    }

    func testPracticeFlow() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlertIfPresent()

        // Complete onboarding if this is a fresh install.
        completeOnboardingIfPresent(app)
        dismissSystemAlertIfPresent()

        // Go to the Catalog.
        XCTAssertTrue(tabButton(app, "Каталог").waitForExistence(timeout: 15))
        tabButton(app, "Каталог").tap()

        // A1 → theme "Существительное и его окружение".
        let theme = app.staticTexts["Существительное и его окружение"]
        XCTAssertTrue(theme.waitForExistence(timeout: 15), "noun theme row not found")
        theme.tap()

        // Open the card "Род существительных" (A1-07).
        let card = app.staticTexts["Род существительных"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "A1-07 card row not found")
        card.tap()

        // Tap the "Практика · N" button in the card reader.
        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15), "Практика button not found")
        practice.tap()

        // Exercise screen: answer, check, expect feedback, continue.
        let check = app.buttons["Проверить"]
        XCTAssertTrue(check.waitForExistence(timeout: 15), "exercise screen (Проверить) not shown")

        // Choose the first available multiple-choice option (article el/la etc.).
        for opt in ["la", "el", "una", "un", "los", "las"] {
            let b = app.buttons[opt]
            if b.exists { b.tap(); break }
        }
        XCTAssertTrue(check.isEnabled, "submit should be enabled after choosing an option")
        check.tap()

        // Feedback appears (Верно or Неверно), then continue.
        let verdict = app.staticTexts["Верно"].exists || app.staticTexts["Неверно"].exists
            || app.staticTexts["Верно"].waitForExistence(timeout: 5)
            || app.staticTexts["Неверно"].waitForExistence(timeout: 5)
        XCTAssertTrue(verdict, "no correct/incorrect feedback shown after checking")

        let cont = app.buttons["Продолжить"].exists ? app.buttons["Продолжить"] : app.buttons["Готово"]
        XCTAssertTrue(cont.waitForExistence(timeout: 5), "continue/done action not shown")
        cont.tap()

        // We either advanced to another exercise or reached the completion state.
        let advanced = app.buttons["Проверить"].waitForExistence(timeout: 5)
            || app.staticTexts["Готово!"].waitForExistence(timeout: 5)
        XCTAssertTrue(advanced, "did not advance to next exercise or completion")
    }

    /// Drives to the picture-matching smoke-test exercise (first exercise of card
    /// A1-30) and confirms its labels + images render from the bundle.
    func testPictureMatchingRenders() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlertIfPresent()
        completeOnboardingIfPresent(app)
        dismissSystemAlertIfPresent()

        XCTAssertTrue(tabButton(app, "Каталог").waitForExistence(timeout: 15))
        tabButton(app, "Каталог").tap()

        let theme = app.staticTexts["Числа, время и быт"]
        XCTAssertTrue(theme.waitForExistence(timeout: 15), "a1-5 theme row not found")
        theme.tap()

        let card = app.staticTexts["Бытовая лексика A1"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "A1-30 card row not found")
        card.tap()

        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15), "Практика button not found")
        practice.tap()

        // First exercise is the picture-matching one (animals): its labels render.
        XCTAssertTrue(app.staticTexts["perro"].waitForExistence(timeout: 15), "picture-matching label 'perro' not shown")
        XCTAssertTrue(app.staticTexts["gato"].exists, "picture-matching label 'gato' not shown")
        // Images render (AsyncImage → bundled asset); at least one image element present.
        XCTAssertTrue(app.images.firstMatch.waitForExistence(timeout: 5), "no image rendered on the picture-matching screen")
        sleep(6)   // window for an external screenshot
    }

    /// Opens Settings → «О приложении» and confirms the OpenMoji attribution shows.
    func testAboutScreen() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlertIfPresent()
        completeOnboardingIfPresent(app)
        dismissSystemAlertIfPresent()

        XCTAssertTrue(tabButton(app, "Настройки").waitForExistence(timeout: 15))
        tabButton(app, "Настройки").tap()

        let about = app.staticTexts["О приложении"]
        XCTAssertTrue(about.waitForExistence(timeout: 15), "«О приложении» entry not found")
        about.tap()

        XCTAssertTrue(app.staticTexts["OpenMoji"].waitForExistence(timeout: 10), "OpenMoji credit not shown")
        XCTAssertTrue(app.staticTexts["CC BY-SA 4.0"].exists, "OpenMoji license not shown")
        sleep(6)   // window for an external screenshot
    }
}

/// Drives the Settings → Напоминания flow on the simulator, covering the two
/// reported bugs: (1) a second reminder time is added and shown in the list, and
/// (2) the enabled state and times persist when leaving and re-entering the screen.
@MainActor
final class RemindersSettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEnableAddTimeAndPersistAcrossReentry() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)   // skip reminders in onboarding; configure here
        dismissSystemAlerts(app)

        // Settings → Напоминания.
        XCTAssertTrue(tabButton(app, "Настройки").waitForExistence(timeout: 15))
        tabButton(app, "Настройки").tap()
        let entry = app.staticTexts["Напоминания"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15), "Reminders entry not found in Settings")
        entry.tap()

        // Enable — seeds the default 20:00 time. The list rendering from the
        // observed config proves the reactivity fix (bug #1's root).
        let toggle = app.switches["remindersEnabledToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "reminders toggle not found")
        if (toggle.value as? String) != "1" { toggle.tap() }
        dismissSystemAlerts(app)   // notification permission prompt (choice irrelevant to persistence)

        let rows = app.staticTexts.matching(identifier: "reminderTimeRow")
        XCTAssertTrue(waitForCount(rows, atLeast: 1, timeout: 10),
                      "seeded reminder time did not appear after enabling")

        // Add a second time. The add-picker defaults to the current time (≠ 20:00),
        // so this yields a distinct second row — directly exercising bug #1.
        XCTAssertTrue(app.buttons["Добавить"].waitForExistence(timeout: 10))
        app.buttons["Добавить"].tap()
        XCTAssertTrue(waitForCount(rows, atLeast: 2, timeout: 10),
                      "second reminder time was not added/shown (bug #1)")

        // Leave and re-enter to confirm nothing resets (bug #2).
        app.navigationBars.buttons.element(boundBy: 0).tap()   // back to Settings
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()

        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "1",
                       "reminders reset to off on re-entry (bug #2)")
        XCTAssertTrue(waitForCount(rows, atLeast: 2, timeout: 10),
                      "reminder times did not persist across re-entry (bug #2)")
    }
}
