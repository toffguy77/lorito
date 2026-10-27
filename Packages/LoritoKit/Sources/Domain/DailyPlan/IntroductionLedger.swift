import Foundation

/// Which items were introduced on a given day: an item is introduced on the
/// day of its earliest graded `StudyEvent`. New-item quotas subtract today's
/// introductions so recomposing the plan during the day never raises the total.
/// Pure; uses the app's day calendar.
public struct IntroductionLedger: Sendable, Equatable {
    /// Ids introduced on `day`, in the order of their first grade.
    public let introducedToday: [String]

    public var count: Int { introducedToday.count }

    public init(events: [StudyEvent], day: Date, calendar: Calendar = .utcDay) {
        var firstGrade: [String: Date] = [:]
        for event in events where event.grade != nil {
            if let seen = firstGrade[event.cardID], seen <= event.date { continue }
            firstGrade[event.cardID] = event.date
        }
        introducedToday = firstGrade
            .filter { calendar.isDate($0.value, inSameDayAs: day) }
            .sorted { $0.value != $1.value ? $0.value < $1.value : $0.key < $1.key }
            .map(\.key)
    }
}
