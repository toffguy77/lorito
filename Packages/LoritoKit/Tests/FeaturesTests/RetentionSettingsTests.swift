import Foundation
import Testing
import Domain
import Persistence
@testable import Features

@Suite("Desired retention setting")
@MainActor
struct RetentionSettingsTests {
    @Test("Default 90 %; change persists, keeps other settings and leaves due dates alone")
    func persists() throws {
        let container = try PersistenceController.makeContainer(config: .init(inMemory: true))
        let store = SwiftDataUserDataStore(container: container)
        var s = UserSettings.default
        s.targetLevel = .b1
        try store.saveSettings(s)
        let due = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let review = ReviewState(cardID: "A1-01", interval: 10, repetitions: 3, dueDate: due, status: .review)
        try store.upsertReview(review)

        let model = RetentionSettingsModel(store: store)
        #expect(model.percent == 90)
        model.percent = 95
        #expect(try store.loadSettings().desiredRetention == 0.95)
        #expect(try store.loadSettings().targetLevel == .b1)
        #expect(try store.review(for: "A1-01") == review)
        #expect(RetentionSettingsModel(store: store).percent == 95)
    }

    @Test("Out-of-range values clamp to 80–95 %")
    func clamps() {
        #expect(UserSettings(desiredRetention: 0.5).desiredRetention == 0.80)
        var s = UserSettings.default
        s.desiredRetention = 0.99
        #expect(s.desiredRetention == 0.95)
    }
}
