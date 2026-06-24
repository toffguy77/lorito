import Testing
import Foundation
import Domain
@testable import Features

/// Records scheduling calls without touching the system. Models a pending set
/// keyed by identifier so idempotency and scoped removal are observable.
@MainActor
private final class FakeScheduler: NotificationScheduling {
    var status: ReminderAuthorization
    /// Status the system "prompt" resolves to (defaults to current status).
    var promptResult: ReminderAuthorization?
    var requestCount = 0
    var pending: [String: ReminderRequest] = [:]

    init(status: ReminderAuthorization) { self.status = status }

    func authorizationStatus() async -> ReminderAuthorization { status }
    func requestAuthorization() async -> ReminderAuthorization {
        requestCount += 1
        status = promptResult ?? status
        return status
    }
    func schedule(_ requests: [ReminderRequest]) async {
        for r in requests { pending[r.id] = r }
    }
    func removeReminders(withPrefix prefix: String) async {
        pending = pending.filter { !$0.key.hasPrefix(prefix) }
    }
}

private final class MemStore: UserDataStore {
    var settings = UserSettings(targetLevel: .a1, selectedThemeIDs: ["a1-1"], dailyNewCardCount: 3)
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

private let catalog = ContentCatalog(
    themes: [Theme(id: "a1-1", level: .a1, title: "Тема", order: 1)],
    cards: (1...5).map { Card(id: "A1-0\($0)", level: .a1, themeID: "a1-1", order: $0, title: "c", body: "b") }
)

private func utc() -> Calendar {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
}
private let now = utc().date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 6))!

@Suite("Reminder service")
@MainActor
struct ReminderServiceTests {
    private func service(_ scheduler: FakeScheduler, _ store: MemStore = MemStore()) -> ReminderService {
        ReminderService(scheduler: scheduler, store: store, catalog: catalog, calendar: utc())
    }

    @Test("notDetermined → prompts for authorization, then schedules when granted")
    func enableRequestsAuth() async {
        let fake = FakeScheduler(status: .notDetermined)
        fake.promptResult = .authorized  // user grants at the prompt
        let svc = service(fake)
        let result = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)], now: now)
        #expect(fake.requestCount == 1)  // notDetermined triggered the prompt
        #expect(result == .authorized)
        #expect(!fake.pending.isEmpty)
    }

    @Test("Denied authorization schedules nothing")
    func deniedSchedulesNothing() async {
        let fake = FakeScheduler(status: .denied)
        let svc = service(fake)
        let result = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)], now: now)
        #expect(result == .denied)
        #expect(fake.pending.isEmpty)
    }

    @Test("Authorized enable schedules reminder requests")
    func authorizedSchedules() async {
        let fake = FakeScheduler(status: .authorized)
        let svc = service(fake)
        _ = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)], now: now)
        #expect(!fake.pending.isEmpty)
        #expect(fake.pending.keys.allSatisfy { $0.hasPrefix(ReminderConstants.identifierPrefix) })
    }

    @Test("Reschedule is idempotent: same pending set after repeated runs")
    func idempotent() async {
        let fake = FakeScheduler(status: .authorized)
        let store = MemStore()
        store.settings.reminderConfig = ReminderConfig(enabled: true, times: [ReminderTime(hour: 9, minute: 0)])
        let svc = service(fake, store)
        await svc.reschedule(now: now)
        let first = Set(fake.pending.keys)
        await svc.reschedule(now: now)
        let second = Set(fake.pending.keys)
        #expect(first == second)
        #expect(!first.isEmpty)
    }

    @Test("Removal is scoped to reminder identifiers; foreign requests survive")
    func scopedRemoval() async {
        let fake = FakeScheduler(status: .authorized)
        // Seed a foreign pending request that must not be removed.
        fake.pending["other.app.request"] = ReminderRequest(
            id: "other.app.request", fireDate: now, title: "x", body: "y", route: "z"
        )
        let store = MemStore()
        store.settings.reminderConfig = ReminderConfig(enabled: true, times: [ReminderTime(hour: 9, minute: 0)])
        let svc = service(fake, store)
        await svc.reschedule(now: now)
        #expect(fake.pending["other.app.request"] != nil)  // untouched
        #expect(fake.pending.keys.contains { $0.hasPrefix(ReminderConstants.identifierPrefix) })
    }

    @Test("Disable clears scheduling intent and removes reminders")
    func disableClears() async {
        let fake = FakeScheduler(status: .authorized)
        let store = MemStore()
        let svc = service(fake, store)
        _ = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)], now: now)
        #expect(!fake.pending.isEmpty)
        await svc.disable()
        #expect(fake.pending.isEmpty)
        #expect(!store.settings.remindersEnabled)
    }
}

@Suite("Reminders router")
@MainActor
struct RemindersRouterTests {
    @Test("A reminder route opens Today; other routes do not")
    func routing() {
        let router = RemindersRouter()
        router.handle(userInfo: ["route": ReminderRoute.today])
        #expect(router.openToday)
        router.consume()
        #expect(!router.openToday)
        router.handle(userInfo: ["route": "something-else"])
        #expect(!router.openToday)
    }
}
