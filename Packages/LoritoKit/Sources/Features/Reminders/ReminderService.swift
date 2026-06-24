import Foundation
import Observation
import Domain

/// Coordinates reminders: persists `reminderConfig`, runs the authorization
/// flow, resolves per-day due/new counts from `daily-plan`, and applies the pure
/// `ReminderPlanner` decision through a `NotificationScheduling` backend. Used
/// for the enable flow and every reschedule trigger.
@MainActor
@Observable
public final class ReminderService {
    private let scheduler: NotificationScheduling
    private let store: UserDataStore
    private let catalog: ContentCatalog
    private let calendar: Calendar

    /// Latest known authorization (drives the denied-guidance UI).
    public private(set) var authorization: ReminderAuthorization = .notDetermined

    public init(
        scheduler: NotificationScheduling,
        store: UserDataStore,
        catalog: ContentCatalog,
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.store = store
        self.catalog = catalog
        self.calendar = calendar
    }

    public var config: ReminderConfig {
        ((try? store.loadSettings()) ?? .default).reminderConfig
    }

    // MARK: - Enable / disable

    /// Enable reminders with the given times, running the authorization flow.
    /// Schedules only when authorized/provisional; returns the resulting status
    /// so the UI can show Settings guidance when denied.
    @discardableResult
    public func enable(times: [ReminderTime], now: Date = Date()) async -> ReminderAuthorization {
        var settings = (try? store.loadSettings()) ?? .default
        var cfg = settings.reminderConfig
        cfg.enable()
        for time in times { cfg.addTime(time) }
        settings.reminderConfig = cfg
        try? store.saveSettings(settings)

        let status = await ensureAuthorization()
        authorization = status
        if status == .authorized || status == .provisional {
            await reschedule(now: now)
        }
        return status
    }

    public func disable() async {
        var settings = (try? store.loadSettings()) ?? .default
        var cfg = settings.reminderConfig
        cfg.disable()
        settings.reminderConfig = cfg
        try? store.saveSettings(settings)
        await scheduler.removeReminders(withPrefix: ReminderConstants.identifierPrefix)
    }

    public func addTime(_ time: ReminderTime, now: Date = Date()) async {
        var settings = (try? store.loadSettings()) ?? .default
        var cfg = settings.reminderConfig
        cfg.addTime(time)
        settings.reminderConfig = cfg
        try? store.saveSettings(settings)
        await reschedule(now: now)
    }

    public func removeTime(_ time: ReminderTime, now: Date = Date()) async {
        var settings = (try? store.loadSettings()) ?? .default
        var cfg = settings.reminderConfig
        cfg.removeTime(time)
        settings.reminderConfig = cfg
        try? store.saveSettings(settings)
        await reschedule(now: now)
    }

    // MARK: - Authorization

    public func refreshAuthorization() async {
        authorization = await scheduler.authorizationStatus()
    }

    private func ensureAuthorization() async -> ReminderAuthorization {
        let status = await scheduler.authorizationStatus()
        if status == .notDetermined {
            return await scheduler.requestAuthorization()
        }
        return status
    }

    // MARK: - Reschedule (every trigger funnels here; idempotent)

    /// Clear prior reminder requests and schedule the current decision. Safe to
    /// call on settings change, session completion, launch, and day rollover.
    public func reschedule(now: Date = Date()) async {
        await scheduler.removeReminders(withPrefix: ReminderConstants.identifierPrefix)

        let settings = (try? store.loadSettings()) ?? .default
        let cfg = settings.reminderConfig
        guard cfg.enabled, !cfg.times.isEmpty else { return }

        let status = await scheduler.authorizationStatus()
        authorization = status
        guard status == .authorized || status == .provisional else { return }

        let reviews = (try? store.allReviews()) ?? []
        let cards = catalog.cards
        let countsForDay: (Date) -> DayCounts = { day in
            let plan = DailyPlanner.composePlan(
                DailyPlanRequest(cards: cards, reviews: reviews, settings: settings, today: day)
            )
            return DayCounts(due: plan.counts.dueCount, new: plan.counts.newCount)
        }

        let requests = ReminderPlanner.requests(
            times: cfg.times, now: now, calendar: calendar, counts: countsForDay
        )
        await scheduler.schedule(requests)
    }
}
