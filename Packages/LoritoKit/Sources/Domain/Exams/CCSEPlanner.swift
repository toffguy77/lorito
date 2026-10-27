import Foundation

/// CCSE questions as review items `ccse:<item-id>`: due ones (most overdue
/// first) plus new ones within `ccseDailyNewLimit` and the shared daily budget.
public enum CCSEPlanner {
    public static let maxDuePerDay = 20

    public static func itemID(_ examItemID: String) -> String { "ccse:\(examItemID)" }

    public static func plan(bank: [ExamItem], reviews: [ReviewState], settings: UserSettings,
                            introducedToday: [ItemKind: Int], today: Date, calendar: Calendar = .learningDay) -> [String] {
        let active = bank.filter { $0.exam == "ccse" && !$0.retired }
        let ids = Set(active.map { itemID($0.id) })
        let due = reviews
            .filter { ids.contains($0.cardID) && DueSelection.isDue($0, on: today, calendar: calendar) }
            .sorted { $0.dueDate != $1.dueDate ? $0.dueDate < $1.dueDate : $0.cardID < $1.cardID }
            .prefix(maxDuePerDay).map(\.cardID)
        let allowance = DailyBudget.standard(settings: settings).allowances(introducedToday: introducedToday)[.ccse] ?? 0
        let known = Set(reviews.map(\.cardID))
        let new = active.map { itemID($0.id) }.filter { !known.contains($0) }.sorted { a, b in
            (Int(a.split(separator: "-").last ?? "") ?? 0) < (Int(b.split(separator: "-").last ?? "") ?? 0)
        }.prefix(allowance)
        return Array(due) + Array(new)
    }
}
