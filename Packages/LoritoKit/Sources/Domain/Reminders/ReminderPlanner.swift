import Foundation

/// Per-day due/new counts supplied to the scheduling decision (resolved by the
/// caller from `daily-plan`, never computed here).
public struct DayCounts: Equatable, Sendable {
    public let due: Int
    public let new: Int

    public init(due: Int, new: Int) {
        self.due = due
        self.new = new
    }

    public var isEmpty: Bool { due == 0 && new == 0 }
}

/// Authorization state, abstracted from `UNAuthorizationStatus` so Domain stays
/// free of the system framework.
public enum ReminderAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
}

/// A single notification to schedule. A pure value type — the system-backed
/// scheduler maps it onto a `UNNotificationRequest`.
public struct ReminderRequest: Equatable, Sendable, Identifiable {
    public let id: String      // stable identifier under the reserved prefix
    public let fireDate: Date  // concrete local fire datetime
    public let title: String
    public let body: String
    public let route: String   // deep-link marker (e.g. Today)

    public init(id: String, fireDate: Date, title: String, body: String, route: String) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
        self.body = body
        self.route = route
    }
}

public enum ReminderRoute {
    /// Route value carried by reminder notifications: open the Today/study entry.
    public static let today = "today"
}

public enum ReminderConstants {
    /// Reserved namespace for all reminder identifiers (scopes removal).
    public static let identifierPrefix = "lorito.reminder."
    /// Forward scheduling horizon in days.
    public static let horizonDays = 7
    /// Per-day time cap. horizonDays × maxTimesPerDay = 63 ≤ the iOS limit.
    public static let maxTimesPerDay = 9
    /// iOS pending-request limit; the decision never exceeds this.
    public static let maxPendingReminders = 64
}

/// The pure scheduling decision: given the configured times, the per-day counts,
/// and an injected "now", produce the exact set of notification requests. No
/// I/O, no system notification API, no ambient clock. Identical inputs yield
/// identical output.
public enum ReminderPlanner {

    public static func requests(
        times: [ReminderTime],
        now: Date,
        calendar: Calendar,
        counts: (Date) -> DayCounts
    ) -> [ReminderRequest] {
        let cappedTimes = Array(Set(times)).sorted().prefix(ReminderConstants.maxTimesPerDay)
        guard !cappedTimes.isEmpty else { return [] }

        let startToday = calendar.startOfDay(for: now)
        var result: [ReminderRequest] = []

        for dayOffset in 0..<ReminderConstants.horizonDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startToday) else { continue }
            let dayCounts = counts(day)
            if dayCounts.isEmpty { continue }  // skip days with nothing due

            for time in cappedTimes {
                guard let fire = calendar.date(
                    bySettingHour: time.hour, minute: time.minute, second: 0, of: day
                ) else { continue }
                if fire <= now { continue }  // only future times

                result.append(ReminderRequest(
                    id: identifier(for: day, time: time, calendar: calendar),
                    fireDate: fire,
                    title: "Lorito",
                    body: body(due: dayCounts.due, new: dayCounts.new),
                    route: ReminderRoute.today
                ))
            }
        }

        // Soonest first (stable on id), bounded to the pending-request limit.
        result.sort { lhs, rhs in
            if lhs.fireDate != rhs.fireDate { return lhs.fireDate < rhs.fireDate }
            return lhs.id < rhs.id
        }
        return Array(result.prefix(ReminderConstants.maxPendingReminders))
    }

    /// Russian body reflecting the day's counts.
    public static func body(due: Int, new: Int) -> String {
        if due > 0 && new > 0 { return "\(due) на повторение + \(new) новых" }
        if due > 0 { return "\(due) на повторение" }
        return "\(new) новых карточек"
    }

    private static func identifier(for day: Date, time: ReminderTime, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        let dayKey = String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        let timeKey = String(format: "%02d%02d", time.hour, time.minute)
        return "\(ReminderConstants.identifierPrefix)\(dayKey)-\(timeKey)"
    }
}

/// System-notification access, abstracted so production uses
/// `UNUserNotificationCenter` and tests use a fake. The pure `ReminderPlanner`
/// does not depend on this. Main-actor isolated: all scheduling is driven from
/// the UI/service layer.
@MainActor
public protocol NotificationScheduling {
    func authorizationStatus() async -> ReminderAuthorization
    func requestAuthorization() async -> ReminderAuthorization
    func schedule(_ requests: [ReminderRequest]) async
    /// Remove only pending requests whose identifier begins with `prefix`.
    func removeReminders(withPrefix prefix: String) async
}
