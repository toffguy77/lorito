import Foundation

/// A daily reminder time in the user's local calendar (no date component).
public struct ReminderTime: Hashable, Sendable, Comparable, Codable {
    public let hour: Int    // 0–23
    public let minute: Int  // 0–59

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public init(minutesFromMidnight m: Int) {
        self.init(hour: m / 60, minute: m % 60)
    }

    public var minutesFromMidnight: Int { hour * 60 + minute }

    public static func < (lhs: ReminderTime, rhs: ReminderTime) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }
}

/// The concrete shape of `UserSettings.reminderConfig`: an enabled flag plus an
/// ordered set of one or more daily times. Maps onto the foundation
/// `UserSettings.remindersEnabled` / `reminderMinutes` fields without redefining
/// the model.
public struct ReminderConfig: Equatable, Sendable {
    public var enabled: Bool
    /// Ascending, distinct daily times.
    public private(set) var times: [ReminderTime]

    public init(enabled: Bool = false, times: [ReminderTime] = []) {
        self.enabled = enabled
        self.times = Self.normalized(times)
    }

    /// Default time used when reminders are enabled with no time yet.
    public static let defaultTime = ReminderTime(hour: 20, minute: 0)

    private static func normalized(_ times: [ReminderTime]) -> [ReminderTime] {
        Array(Set(times)).sorted()
    }

    // MARK: - Editing helpers (keep ≥1 time whenever enabled)

    public mutating func addTime(_ time: ReminderTime) {
        times = Self.normalized(times + [time])
    }

    /// Remove a time. Removing the final time while enabled is ignored so an
    /// enabled config always has at least one time.
    public mutating func removeTime(_ time: ReminderTime) {
        if enabled, times.count == 1, times.first == time { return }
        times.removeAll { $0 == time }
    }

    /// Enable reminders, seeding a default time if none is set.
    public mutating func enable(defaultTime: ReminderTime = ReminderConfig.defaultTime) {
        enabled = true
        if times.isEmpty { times = [defaultTime] }
    }

    /// Disable reminders (clears scheduling intent; retains the chosen times).
    public mutating func disable() {
        enabled = false
    }
}

public extension UserSettings {
    /// View of the reminder fields as a structured config. Setting it writes the
    /// `remindersEnabled` / `reminderMinutes` fields.
    var reminderConfig: ReminderConfig {
        get {
            ReminderConfig(
                enabled: remindersEnabled,
                times: reminderMinutes.map(ReminderTime.init(minutesFromMidnight:))
            )
        }
        set {
            remindersEnabled = newValue.enabled
            reminderMinutes = newValue.times.map(\.minutesFromMidnight)
        }
    }
}
