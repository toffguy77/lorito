import Testing
import Foundation
@testable import Domain

private let cal = Calendar.learningDay(in: TimeZone(identifier: "UTC")!)
private let today = cal.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 10))!
private func card(_ id: String, _ order: Int, level: CEFRLevel = .a1) -> Card {
    Card(id: id, level: level, themeID: "\(level.rawValue.lowercased())-1", order: order, title: id, body: "")
}
private func requested(_ id: String, minutesAgo: Double) -> RequestedItem {
    RequestedItem(itemID: id, requestedAt: today.addingTimeInterval(-minutesAgo * 60))
}

@Suite("Daily plan: user-requested items (grammar-lens)")
struct RequestedItemsPlanTests {
    let cards = (1...9).map { card(String(format: "A1-%02d", $0), $0) } + [card("B1-02", 2, level: .b1)]

    func newIDs(_ requested: [RequestedItem], reviews: [ReviewState] = [], perDay: Int = 4) -> [String] {
        let s = UserSettings(targetLevel: .a1, dailyNewCardCount: perDay)
        let plan = DailyPlanner.composePlan(DailyPlanRequest(cards: cards, reviews: reviews, settings: s, today: today,
                                                             calendar: cal, requested: requested))
        return plan.queue.filter { $0.kind == .new }.map(\.cardID)
    }

    @Test("Requested card first; at most budget − 1 others follow")
    func first() {
        #expect(newIDs([requested("A1-07", minutesAgo: 5)]) == ["A1-07", "A1-01", "A1-02", "A1-03"])
    }

    @Test("Budget exhausted: the oldest requests today, the rest later")
    func budget() {
        let r = [("A1-09", 1.0), ("A1-08", 6), ("A1-07", 3), ("A1-06", 5), ("A1-05", 4), ("A1-04", 2)]
            .map { requested($0.0, minutesAgo: $0.1) }
        #expect(newIDs(r) == ["A1-08", "A1-06", "A1-05", "A1-07"])
    }

    @Test("Out-of-scope request is introduced (the user asked); items with review state are never moved")
    func scopeAndState() {
        #expect(newIDs([requested("B1-02", minutesAgo: 1)]).first == "B1-02")
        let started = ReviewState(cardID: "A1-07", interval: 9, dueDate: today.addingTimeInterval(9 * 86_400), status: .review)
        let ids = newIDs([requested("A1-07", minutesAgo: 1)], reviews: [started])
        #expect(!ids.contains("A1-07"))
        #expect(ids == ["A1-01", "A1-02", "A1-03", "A1-04"])
    }

    @Test("No requests: plan unchanged")
    func none() {
        #expect(newIDs([]) == ["A1-01", "A1-02", "A1-03", "A1-04"])
    }
}
