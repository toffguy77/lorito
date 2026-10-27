import Foundation
import Domain

/// One line of Today's goal card (study-goal).
public struct TodayGoalLine: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    /// End states are shown once, then hidden.
    public let isEndState: Bool
}

/// Builds Today's goal lines and remembers (device-local) which end states
/// were already shown.
public struct TodayGoalBuilder: @unchecked Sendable {
    static let seenKey = "goal.endStatesSeen"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// UI testing: forget which end states were shown.
    public func reset() { defaults.removeObject(forKey: Self.seenKey) }

    /// `keepShowing`: end-state ids already shown during this visit.
    public func lines(settings: UserSettings, cards: [Card], reviews: [ReviewState], today: Date,
                      keepShowing: Set<String>, calendar: Calendar = .learningDay) -> [TodayGoalLine] {
        let stored = Set(defaults.stringArray(forKey: Self.seenKey) ?? [])
        var seen = stored
        var out: [TodayGoalLine] = []
        if let goal = settings.levelGoal {
            let state = GoalPacing.evaluate(goal, cards: cards, reviews: reviews, selectedThemeIDs: settings.selectedThemeIDs,
                                            today: today, calendar: calendar)
            let title = "Цель: \(goal.targetLevel.rawValue) к \(Self.dateText(goal.targetDate))"
            switch state {
            case .active:
                let p = GoalPacing.progress(goal: goal, cards: cards, reviews: reviews,
                                            selectedThemeIDs: settings.selectedThemeIDs, today: today, calendar: calendar)
                let status = GoalPacing.status(p, dailyNewCardCount: settings.dailyNewCardCount)
                let cardsText = "\(p.cardsLeft) \(RussianPlural.form(p.cardsLeft, one: "карточка", few: "карточки", many: "карточек"))"
                out.append(TodayGoalLine(id: "level", title: title,
                                         detail: "\(Self.daysText(p.learningDaysLeft)) · \(cardsText) · \(status.text)",
                                         isEndState: false))
            case .achieved, .expired:
                let id = "level:\(goal.targetLevel.rawValue):\(Int(goal.targetDate.timeIntervalSince1970)):\(state.rawValue)"
                if !seen.contains(id) || keepShowing.contains(id) {
                    out.append(TodayGoalLine(id: id, title: title,
                                             detail: state == .achieved ? "Цель достигнута — все карточки уровня начаты"
                                                                        : "Срок прошёл — можно поставить новую цель",
                                             isEndState: true))
                    seen.insert(id)
                }
            }
        }
        if let exam = settings.exam {
            let title = "\(exam.kind.title) · \(Self.dateText(exam.date))"
            if ExamCountdown.state(exam, today: today, calendar: calendar) == .active {
                out.append(TodayGoalLine(id: "exam", title: title,
                                         detail: Self.daysText(ExamCountdown.learningDaysLeft(exam, today: today, calendar: calendar)),
                                         isEndState: false))
            } else {
                let id = "exam:\(exam.kind.rawValue):\(Int(exam.date.timeIntervalSince1970))"
                if !seen.contains(id) || keepShowing.contains(id) {
                    out.append(TodayGoalLine(id: id, title: title, detail: "Экзамен позади. ¡Enhorabuena!", isEndState: true))
                    seen.insert(id)
                }
            }
        }
        // Write only on change: a UserDefaults write re-renders views that use
        // @AppStorage, which rebuild Today — writing every time would loop.
        if seen != stored { defaults.set(Array(seen).sorted(), forKey: Self.seenKey) }
        return out
    }

    /// "осталось 1 день / 2 дня / 5 дней"
    nonisolated static func daysText(_ n: Int) -> String {
        "\(RussianPlural.form(n, one: "остался", few: "осталось", many: "осталось")) \(RussianPlural.days(n))"
    }

    nonisolated static func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.setLocalizedDateFormatFromTemplate("d MMMM")
        return f.string(from: date)
    }
}
