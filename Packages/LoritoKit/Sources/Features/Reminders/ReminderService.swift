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

    /// The current reminder configuration, held in memory so the UI observes
    /// every edit (the `@Observable` macro only tracks stored properties). This
    /// is the authoritative copy; mutations write through to the store.
    public private(set) var config: ReminderConfig

    /// True when the most recent settings write failed to persist. The in-memory
    /// `config` stays authoritative; this lets the UI surface the failure rather
    /// than silently drop it.
    public private(set) var persistenceFailed = false

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
        self.config = ((try? store.loadSettings()) ?? .default).reminderConfig
    }

    // MARK: - Persistence (write-through, failures surfaced)

    /// Apply a change to the authoritative in-memory config and persist it,
    /// merging into the latest stored settings so unrelated fields are preserved.
    private func mutateConfig(_ transform: (inout ReminderConfig) -> Void) {
        var cfg = config
        transform(&cfg)
        config = cfg  // authoritative in-memory update (observed by the UI)

        var settings = (try? store.loadSettings()) ?? .default
        settings.reminderConfig = cfg
        do {
            try store.saveSettings(settings)
            persistenceFailed = false
        } catch {
            persistenceFailed = true
        }
    }

    // MARK: - Enable / disable

    /// Enable reminders with the given times, running the authorization flow.
    /// Schedules only when authorized/provisional; returns the resulting status
    /// so the UI can show Settings guidance when denied.
    @discardableResult
    public func enable(times: [ReminderTime], now: Date = Date()) async -> ReminderAuthorization {
        mutateConfig { cfg in
            cfg.enable()
            for time in times { cfg.addTime(time) }
        }

        let status = await ensureAuthorization()
        authorization = status
        if status == .authorized || status == .provisional {
            await reschedule(now: now)
        }
        return status
    }

    public func disable() async {
        mutateConfig { $0.disable() }
        await scheduler.removeReminders(withPrefix: ReminderConstants.identifierPrefix)
    }

    public func addTime(_ time: ReminderTime, now: Date = Date()) async {
        mutateConfig { $0.addTime(time) }
        await reschedule(now: now)
    }

    public func removeTime(_ time: ReminderTime, now: Date = Date()) async {
        mutateConfig { $0.removeTime(time) }
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

        // `config` is the authoritative in-memory copy (init loads it, every
        // mutation updates it); `settings` is only needed for plan composition.
        let settings = (try? store.loadSettings()) ?? .default
        let cfg = config
        guard cfg.enabled, !cfg.times.isEmpty else { return }

        let status = await scheduler.authorizationStatus()
        authorization = status
        guard status == .authorized || status == .provisional else { return }

        let reviews = (try? store.allReviews()) ?? []
        let events = (try? store.allEvents()) ?? []
        let cards = catalog.cards
        let cal = calendar
        let boost = FirstSessionBoostStore.shared.current(today: now)
        let countsForDay: (Date) -> DayCounts = { day in
            let plan = DailyPlanner.composePlan(
                DailyPlanRequest(cards: cards, reviews: reviews,
                                 settings: GoalPacing.planSettings(settings, goal: settings.levelGoal, cards: cards,
                                                                   reviews: reviews, today: day, calendar: cal),
                                 today: day, events: events, firstSession: boost)
            )
            return DayCounts(due: plan.counts.dueCount, new: plan.counts.newCount)
        }

        // Streak resolved once "as of now"; only today carries the at-risk state,
        // so the planner limits any save-streak nudge to today.
        let stats = StatsCalculator.compute(events: events, today: now, calendar: cal)
        let streakForDay: (Date) -> DayStreak = { day in
            let isToday = cal.isDate(day, inSameDayAs: now)
            return DayStreak(
                currentStreak: stats.currentStreak,
                studiedToday: isToday ? stats.studiedToday > 0 : true
            )
        }

        let requests = ReminderPlanner.requests(
            times: cfg.times, now: now, calendar: cal, counts: countsForDay, streak: streakForDay
        )
        await scheduler.schedule(requests)
    }
}
