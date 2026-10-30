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

/// Tap the Settings tab until Settings is showing (a tap during a cover's
/// dismissal animation can be lost).
@MainActor
func openSettingsTab(_ app: XCUIApplication) {
    for _ in 0..<4 {
        tabButton(app, "Настройки").tap()
        if app.navigationBars["Настройки"].waitForExistence(timeout: 3) { return }
    }
}

/// Scroll up until `element` exists and is hittable (clear of the floating tab bar).
@MainActor
func scrollToHittable(_ app: XCUIApplication, _ element: XCUIElement, maxSwipes: Int = 8) {
    for _ in 0..<maxSwipes where !(element.exists && element.isHittable) { app.swipeUp() }
    // One more nudge if it's still near the bottom edge (tab bar overlap).
    if element.exists, element.frame.maxY > app.frame.maxY - 110 { app.swipeUp() }
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

/// Complete first-run onboarding when present: level and themes, then skip the
/// goal, variant, pace, sound and reminder steps, so downstream tests reach the main app.
@MainActor
func completeOnboardingIfPresent(_ app: XCUIApplication, level: String = "A1") {
    guard onboardingPastThemes(app, level: level) else { return }
    skipRestOfOnboarding(app)
    closeFirstSessionIfOpen(app)
}

/// Onboarding up to the goal step: pick `level`, keep all themes. False when the
/// app opened past onboarding.
@MainActor
@discardableResult
func onboardingPastThemes(_ app: XCUIApplication, level: String = "A1") -> Bool {
    // A cold first launch can take well over 8 s: wait for onboarding or the
    // main app, whichever shows first, instead of silently skipping onboarding.
    let deadline = Date().addingTimeInterval(40)
    while Date() < deadline, !app.buttons[level].exists, !tabButton(app, "Сегодня").exists {
        usleep(250_000)
    }
    guard app.buttons[level].exists else {
        if !tabButton(app, "Сегодня").exists { print("[ui] onboarding not found:\n\(app.debugDescription)") }
        return false
    }
    app.buttons[level].tap()
    app.buttons["Далее"].tap()                                   // level → themes
    if app.staticTexts["Что изучать"].waitForExistence(timeout: 10) {
        app.buttons["Далее"].tap()                               // themes → goal
    }
    return app.staticTexts["Цель"].waitForExistence(timeout: 10)
}

/// Skip the remaining setup steps (goal, variant, pace, sound) and the reminder step.
@MainActor
func skipRestOfOnboarding(_ app: XCUIApplication) {
    for _ in 0..<5 {                                             // goal, variant, pace, sound, reminders
        let skip = app.buttons["Пропустить"]
        guard skip.waitForExistence(timeout: 5) else { break }
        skip.tap()
    }
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

/// App Store screenshots (app-store-presence): eight scenes per device class from
/// a seeded demo store (`-lorito-demo-data`) so every screen is full and
/// deterministic — Today plan, revealed card with «Частые ошибки», exams (DELE, CCSE),
/// conjugation trainer, exercise, Spanish variant (setup re-run), recall front,
/// progress. The exams sheet goes last: it covers the tab bar. Headlines are added by `tools/frame_screenshots.swift`.
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

    /// Correct present-tense forms for the trainer's first prompt, typed in so the
    /// screenshot shows an answered card; unknown verbs stay empty.
    private func fillConjugation(_ app: XCUIApplication) {
        let forms: [String: [String: String]] = [
            "ser": ["yo": "soy", "tú": "eres", "él / ella / usted": "es", "nosotros": "somos", "vosotros": "sois", "ellos / ustedes": "son"],
            "estar": ["yo": "estoy", "tú": "estás", "él / ella / usted": "está", "nosotros": "estamos", "vosotros": "estáis", "ellos / ustedes": "están"],
            "tener": ["yo": "tengo", "tú": "tienes", "él / ella / usted": "tiene", "nosotros": "tenemos", "vosotros": "tenéis", "ellos / ustedes": "tienen"],
        ]
        guard app.staticTexts["PRESENTE"].exists || app.staticTexts["Presente"].exists,
              let verb = forms.keys.first(where: { app.staticTexts[$0].exists }), let table = forms[verb] else { return }
        for i in 0..<2 {
            let field = app.textFields["conj.field.\(i)"]
            guard field.exists, let form = table[field.label] else { return }
            field.tap()
            field.typeText(form)
        }
        app.buttons["conj.check"].tap()
        _ = app.staticTexts["Верно"].waitForExistence(timeout: 5)
    }

    func testCaptureScreens() {
        let app = XCUIApplication()
        dismissSystemAlerts(app)

        // 01 — Today: the day's plan, goal countdown, trainers, streak.
        let start = app.buttons["Начать"]
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Today plan not shown")
        snapshot("01Today")

        // 07 — Recall-first card front; 02 — revealed card at «Частые ошибки».
        start.tap()
        let reveal = app.buttons["Показать ответ"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 15))
        snapshot("07Recall")
        reveal.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Хорошо'")).firstMatch.waitForExistence(timeout: 15))
        let mistakes = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Частые ошибки'")).firstMatch
        for _ in 0..<8 where !(mistakes.exists && mistakes.isHittable) { app.swipeUp() }
        snapshot("02Mistakes")
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // 04 — Conjugation trainer from Today.
        let conjugation = app.buttons["today.conjugation"]
        scrollToHittable(app, conjugation)
        XCTAssertTrue(conjugation.waitForExistence(timeout: 15), "no conjugation entry on Today")
        conjugation.tap()
        XCTAssertTrue(app.buttons["conj.check"].waitForExistence(timeout: 15), "conjugation trainer not shown")
        fillConjugation(app)
        snapshot("04Conjugation")
        let close = app.buttons["Закрыть"]
        if close.exists { close.tap() }
        _ = tabButton(app, "Прогресс").waitForExistence(timeout: 10)

        // 08 — Progress: streak, heatmap, long-term memory.
        tabButton(app, "Прогресс").tap()
        _ = app.otherElements["heatmap.today"].firstMatch.waitForExistence(timeout: 10)
        snapshot("08Progress")

        // 05 — Exercise on «Род существительных» (A1-07).
        tabButton(app, "Каталог").tap()
        let theme = app.staticTexts["Существительное и его окружение"]
        scrollToHittable(app, theme)
        XCTAssertTrue(theme.waitForExistence(timeout: 15), "noun theme row not found")
        theme.tap()
        let card = app.staticTexts["Род существительных"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "A1-07 card row not found")
        card.tap()
        let practice = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Практика'")).firstMatch
        XCTAssertTrue(practice.waitForExistence(timeout: 15), "Практика button not found")
        practice.tap()
        XCTAssertTrue(app.buttons["Проверить"].waitForExistence(timeout: 15), "exercise screen not shown")
        let answer = app.buttons["la"]
        if answer.exists { answer.tap() }                                // casa → la, chosen (checking plays audio)
        snapshot("05Exercise")
        if app.buttons["Закрыть"].exists { app.buttons["Закрыть"].tap() }

        // 06 — Spanish variant: the setup re-run from Settings, variant step.
        openSettingsTab(app)
        let again = app.buttons["settings.setupAgain"]
        scrollToHittable(app, again)
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        again.tap()
        XCTAssertTrue(app.staticTexts["Ваш уровень"].waitForExistence(timeout: 10))
        app.buttons["Далее"].tap()
        XCTAssertTrue(app.staticTexts["Что изучать"].waitForExistence(timeout: 10))
        app.buttons["Далее"].tap()
        XCTAssertTrue(app.staticTexts["Цель"].waitForExistence(timeout: 10))
        app.buttons["Пропустить"].tap()
        XCTAssertTrue(app.staticTexts["Какой испанский"].waitForExistence(timeout: 10))
        snapshot("06Variant")

        // 03 — Exams: the DELE A2 track.
        app.buttons["onboarding.close"].tap()
        tabButton(app, "Каталог").tap()
        let exams = app.buttons["catalog.exams"]
        for _ in 0..<4 where !exams.exists {                             // back to the catalog root
            app.navigationBars.buttons.firstMatch.tap()
        }
        scrollToHittable(app, exams)
        XCTAssertTrue(exams.waitForExistence(timeout: 15), "no exams entry in Catalog")
        exams.tap()
        XCTAssertTrue(app.buttons["exams.track.dele-a2"].waitForExistence(timeout: 10))
        snapshot("03Exams")                                              // both tracks: DELE A2 and CCSE
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
        // vocabulary-decks: FrequencyWords credit (source + CC BY-SA 4.0).
        XCTAssertTrue(app.staticTexts["FrequencyWords"].exists, "FrequencyWords credit not shown")
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
