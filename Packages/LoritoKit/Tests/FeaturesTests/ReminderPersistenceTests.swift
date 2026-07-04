import Testing
import Foundation
import Domain
import Persistence
@testable import Features

/// End-to-end persistence for reminders through the REAL SwiftData store: the
/// automatable half of the "enable, add a time, leave and re-enter Settings"
/// acceptance. A second `ReminderService` built from a fresh container on the
/// same store file must observe the enabled state and both times — i.e. the
/// config survives a simulated relaunch (the root of the "state resets" bug).
@MainActor
@Suite("Reminder persistence (real SwiftData)")
struct ReminderPersistenceTests {

    @MainActor
    private final class NoopScheduler: NotificationScheduling {
        func authorizationStatus() async -> ReminderAuthorization { .authorized }
        func requestAuthorization() async -> ReminderAuthorization { .authorized }
        func schedule(_ requests: [ReminderRequest]) async {}
        func removeReminders(withPrefix prefix: String) async {}
    }

    private let catalog = ContentCatalog(
        themes: [Theme(id: "a1-1", level: .a1, title: "Тема", order: 1)],
        cards: [Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "c", body: "b")]
    )

    @Test("Enabled state and both times survive a simulated relaunch")
    func configSurvivesRelaunch() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lorito-reminders-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Session 1: enable reminders and add a second time via the service.
        do {
            let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
            let svc = ReminderService(scheduler: NoopScheduler(), store: store, catalog: catalog)
            _ = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)])
            await svc.addTime(ReminderTime(hour: 20, minute: 0))
            #expect(svc.config.enabled)
            #expect(svc.config.times.count == 2)
        }

        // Session 2: fresh container + service from the same file (re-entry / relaunch).
        let store2 = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
        let svc2 = ReminderService(scheduler: NoopScheduler(), store: store2, catalog: catalog)
        #expect(svc2.config.enabled)
        #expect(svc2.config.times == [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 20, minute: 0)])
    }

    @Test("Disabling persists across a simulated relaunch")
    func disablePersists() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lorito-reminders-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
            let svc = ReminderService(scheduler: NoopScheduler(), store: store, catalog: catalog)
            _ = await svc.enable(times: [ReminderTime(hour: 9, minute: 0)])
            await svc.disable()
            #expect(!svc.config.enabled)
        }

        let store2 = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(url: url)))
        let svc2 = ReminderService(scheduler: NoopScheduler(), store: store2, catalog: catalog)
        #expect(!svc2.config.enabled)
    }
}
