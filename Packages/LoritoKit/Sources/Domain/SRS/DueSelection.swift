import Foundation

/// Pure helpers for selecting which cards are due to study on a given day.
public enum DueSelection {

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// A card is due when it is being learned or reviewed and its dueDate has
    /// arrived. `new` cards are introduced via the daily new-card quota, not
    /// here; `suspended` cards are never due.
    public static func isDue(_ state: ReviewState, on today: Date) -> Bool {
        switch state.status {
        case .suspended, .new:
            return false
        case .learning, .review:
            let start = calendar.startOfDay(for: today)
            return calendar.startOfDay(for: state.dueDate) <= start
        }
    }

    public static func dueCards(from states: [ReviewState], on today: Date) -> [ReviewState] {
        states.filter { isDue($0, on: today) }
    }
}
