import XCTest

/// study-buddy: without iCloud sync (UI testing uses a local in-memory store)
/// Progress explains why and offers no invite.
@MainActor
final class StudyBuddyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testUnavailableWithoutICloud() throws {
        let app = XCUIApplication()
        launchFresh(app)
        dismissSystemAlerts(app)
        completeOnboardingIfPresent(app)
        dismissSystemAlerts(app)
        closeFirstSessionIfOpen(app)

        tabButton(app, "Прогресс").tap()
        let note = app.descendants(matching: .any)["buddy.unavailable"]
        _ = note.waitForExistence(timeout: 10)
        scrollToHittable(app, note, maxSwipes: 10)
        XCTAssertTrue(note.exists, "no unavailable explanation")
        XCTAssertTrue(note.label.contains("iCloud"), note.label)
        XCTAssertFalse(app.buttons["buddy.invite"].exists, "invite offered without iCloud")
    }
}
