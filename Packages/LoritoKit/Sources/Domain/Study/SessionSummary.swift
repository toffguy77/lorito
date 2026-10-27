/// One grade given during a study session, in order.
public struct SessionGrade: Sendable, Hashable {
    public let cardID: String
    public let grade: Grade

    public init(cardID: String, grade: Grade) {
        self.cardID = cardID
        self.grade = grade
    }
}

/// What a finished study session shows. Pure function of the session's grades
/// and the stats after the last write.
public struct SessionSummary: Sendable, Equatable {
    /// Distinct cards graded.
    public let studied: Int
    /// Share (0–100, rounded) of cards whose first grade was Хорошо or Легко.
    public let firstTryPercent: Int
    public let currentStreak: Int
    public let bestStreak: Int
    /// Current streak equals the best and is greater than 1.
    public let isNewRecord: Bool
    /// Up to three theme ids of cards graded Опять/Трудно, most frequent first.
    public let revisitThemeIDs: [String]

    public static let maxRevisitThemes = 3

    public static func make(grades: [SessionGrade], cardsByID: [String: Card], stats: StudyStats) -> SessionSummary {
        var firstGrade: [String: Grade] = [:]
        var order: [String] = []
        // Only grammar cards are counted (drills have their own summaries).
        let grades = grades.filter { ItemKind.parse($0.cardID) == .card }
        for g in grades where firstGrade[g.cardID] == nil {
            firstGrade[g.cardID] = g.grade
            order.append(g.cardID)
        }
        let studied = order.count
        let remembered = order.filter { [.good, .easy].contains(firstGrade[$0]) }.count
        let percent = studied == 0 ? 0 : Int((Double(remembered) * 100 / Double(studied)).rounded())

        // Themes of weak grades: count per theme, ties broken by first appearance.
        var counts: [String: Int] = [:]
        var themeOrder: [String] = []
        for g in grades where g.grade == .again || g.grade == .hard {
            guard let theme = cardsByID[g.cardID]?.themeID else { continue }
            if counts[theme] == nil { themeOrder.append(theme) }
            counts[theme, default: 0] += 1
        }
        let revisit = themeOrder.enumerated()
            .sorted { a, b in
                let (ca, cb) = (counts[a.element]!, counts[b.element]!)
                return ca != cb ? ca > cb : a.offset < b.offset
            }
            .prefix(maxRevisitThemes)
            .map(\.element)

        return SessionSummary(
            studied: studied,
            firstTryPercent: percent,
            currentStreak: stats.currentStreak,
            bestStreak: stats.bestStreak,
            isNewRecord: stats.currentStreak == stats.bestStreak && stats.currentStreak > 1,
            revisitThemeIDs: Array(revisit)
        )
    }
}
