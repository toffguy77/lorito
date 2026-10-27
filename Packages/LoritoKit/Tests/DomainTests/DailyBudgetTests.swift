import Testing
@testable import Domain

@Suite("Daily budget")
struct DailyBudgetTests {
    @Test("Spec: budget 10 with quotas cards 5 / conjugations 5 / words 5 → 5 cards, 5 conjugations, 0 words")
    func binding() {
        let budget = DailyBudget(total: 10, quotas: [.card: 5, .conjugation: 5, .word: 5])
        let a = budget.allowances(introducedToday: [:])
        #expect(a[.card] == 5 && a[.conjugation] == 5 && a[.word] == 0 && a[.ccse] == 0)
    }

    @Test("Non-binding budget gives every quota in full")
    func nonBinding() {
        let a = DailyBudget(total: 10, quotas: [.card: 3, .conjugation: 2]).allowances(introducedToday: [:])
        #expect(a[.card] == 3 && a[.conjugation] == 2 && a[.word] == 0)
    }

    @Test("Today's introductions reduce both the kind's quota and the budget")
    func introduced() {
        let budget = DailyBudget(total: 10, quotas: [.card: 5, .conjugation: 5, .word: 5])
        let a = budget.allowances(introducedToday: [.card: 2, .conjugation: 5])
        // 7 used → 3 left: cards get 3 (quota 5 − 2), conjugations 0 (quota spent), words 0 (budget spent).
        #expect(a[.card] == 3 && a[.conjugation] == 0 && a[.word] == 0)
    }

    @Test("Defaults: budget 10, conjugation and word quotas 0, cards from the setting")
    func defaults() {
        let budget = DailyBudget.standard(settings: UserSettings(targetLevel: .a1, selectedThemeIDs: [], dailyNewCardCount: 3))
        #expect(budget.total == 10)
        #expect(budget.quotas[.card] == 3)
        #expect((budget.quotas[.conjugation] ?? 0) == 0 && (budget.quotas[.word] ?? 0) == 0)
    }

    @Test("Card quota above the budget is capped by the budget")
    func capped() {
        let a = DailyBudget(total: 10, quotas: [.card: 15]).allowances(introducedToday: [:])
        #expect(a[.card] == 10)
    }
}
