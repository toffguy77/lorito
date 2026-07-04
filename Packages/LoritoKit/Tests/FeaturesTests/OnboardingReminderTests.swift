import Testing
import Foundation
import Domain
@testable import Features

/// Exercises the onboarding reminder-step composition: enabling reminders (via
/// `ReminderService`) and persisting scope + completion (via `ScopeSelectionModel`)
/// against a shared store, verifying neither write clobbers the other.
@MainActor
@Suite("Onboarding reminder step")
struct OnboardingReminderTests {

    private struct SaveError: Error {}

    private final class Store: UserDataStore {
        var settings = UserSettings.default
        var reviews: [String: ReviewState] = [:]
        var events: [StudyEvent] = []
        func loadSettings() throws -> UserSettings { settings }
        func saveSettings(_ s: UserSettings) throws { settings = s }
        func allReviews() throws -> [ReviewState] { Array(reviews.values) }
        func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
        func upsertReview(_ review: ReviewState) throws { reviews[review.cardID] = review }
        func appendEvent(_ event: StudyEvent) throws { events.append(event) }
        func allEvents() throws -> [StudyEvent] { events }
    }

    private final class FakeScheduler: NotificationScheduling {
        var status: ReminderAuthorization
        var pending: [String: ReminderRequest] = [:]
        init(status: ReminderAuthorization) { self.status = status }
        func authorizationStatus() async -> ReminderAuthorization { status }
        func requestAuthorization() async -> ReminderAuthorization { status }
        func schedule(_ requests: [ReminderRequest]) async { for r in requests { pending[r.id] = r } }
        func removeReminders(withPrefix prefix: String) async {
            pending = pending.filter { !$0.key.hasPrefix(prefix) }
        }
    }

    private let catalog = ContentCatalog(
        themes: [Theme(id: "a1-1", level: .a1, title: "Тема", order: 1)],
        cards: [Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "c", body: "b")]
    )

    private func studyableModel(_ store: Store) -> ScopeSelectionModel {
        let model = ScopeSelectionModel(store: store, catalog: catalog)
        model.selectLevel(.a1)
        model.selectAllThemes()
        return model
    }

    @Test("Confirming a time enables reminders and completes onboarding")
    func confirmEnablesAndCompletes() async {
        let store = Store()
        let scheduler = FakeScheduler(status: .authorized)
        let service = ReminderService(scheduler: scheduler, store: store, catalog: catalog)
        let model = studyableModel(store)

        // Onboarding "Готово": enable first, then persist scope + completion.
        _ = await service.enable(times: [ReminderTime(hour: 20, minute: 0)])
        let completed = model.persist(completingOnboarding: true)

        #expect(completed)
        #expect(store.settings.remindersEnabled)
        #expect(store.settings.reminderMinutes == [20 * 60])
        #expect(store.settings.didCompleteOnboarding)
        #expect(store.settings.targetLevel == .a1)  // scope not clobbered by the reminder write
    }

    @Test("Skipping leaves reminders off but still completes onboarding")
    func skipLeavesRemindersOff() async {
        let store = Store()
        let model = studyableModel(store)

        // Onboarding "Пропустить": persist only, no enable/authorization.
        let completed = model.persist(completingOnboarding: true)

        #expect(completed)
        #expect(!store.settings.remindersEnabled)
        #expect(store.settings.reminderMinutes.isEmpty)
        #expect(store.settings.didCompleteOnboarding)
    }

    @Test("Denied authorization still completes onboarding without scheduling")
    func deniedStillCompletes() async {
        let store = Store()
        let scheduler = FakeScheduler(status: .denied)
        let service = ReminderService(scheduler: scheduler, store: store, catalog: catalog)
        let model = studyableModel(store)

        let status = await service.enable(times: [ReminderTime(hour: 20, minute: 0)])
        let completed = model.persist(completingOnboarding: true)

        #expect(status == .denied)
        #expect(scheduler.pending.isEmpty)   // nothing scheduled when denied
        #expect(completed)                   // onboarding not blocked
        #expect(store.settings.didCompleteOnboarding)
        #expect(store.settings.remindersEnabled)  // intent recorded; scheduling gated on auth
    }
}
