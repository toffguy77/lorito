import Foundation

public extension Calendar {
    /// The learning day: the local calendar day in the device's current time
    /// zone, boundary at local midnight. Every day-based rule (due dates, the
    /// daily plan, streaks, "today" counts, trap of the day) uses it; history
    /// is bucketed on read, so a time-zone change may merge or split a day.
    static var learningDay: Calendar { learningDay(in: .current) }

    /// The learning-day calendar for a given time zone (tests, widgets).
    static func learningDay(in timeZone: TimeZone) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }
}
