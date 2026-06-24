import Testing
import Foundation
@testable import Domain

private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(year: y, month: m, day: d))!
}

@Suite("Due selection")
struct DueSelectionTests {
    let today = day(2026, 6, 23)

    @Test("Review/learning due when dueDate <= today")
    func dueWhenArrived() {
        let due = ReviewState(cardID: "A", dueDate: day(2026, 6, 20), status: .review)
        let later = ReviewState(cardID: "B", dueDate: day(2026, 6, 30), status: .review)
        #expect(DueSelection.isDue(due, on: today))
        #expect(!DueSelection.isDue(later, on: today))
    }

    @Test("New cards are not due")
    func newNotDue() {
        let s = ReviewState(cardID: "A", dueDate: day(2026, 1, 1), status: .new)
        #expect(!DueSelection.isDue(s, on: today))
    }

    @Test("Suspended cards are never due even when overdue")
    func suspendedNotDue() {
        let s = ReviewState(cardID: "A", dueDate: day(2020, 1, 1), status: .suspended)
        #expect(!DueSelection.isDue(s, on: today))
    }

    @Test("dueCards filters the set")
    func filters() {
        let states = [
            ReviewState(cardID: "A", dueDate: day(2026, 6, 1), status: .review),
            ReviewState(cardID: "B", dueDate: day(2026, 6, 1), status: .suspended),
            ReviewState(cardID: "C", dueDate: day(2026, 6, 1), status: .new),
            ReviewState(cardID: "D", dueDate: day(2026, 6, 23), status: .learning),
        ]
        let due = DueSelection.dueCards(from: states, on: today).map(\.cardID)
        #expect(due == ["A", "D"])
    }
}
