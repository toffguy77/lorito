import Foundation

/// Previews, per grade, when a card would next be due — by running the real
/// `FSRSScheduler` on the current state without persisting anything. Pure and
/// deterministic. At the maximum interval two grades may share a caption.
public enum IntervalPreview {
    /// Display caption per grade for a card in `state` (`nil` = never studied).
    public static func captions(for state: ReviewState?, today: Date, retention: Double = 0.9,
                                calendar: Calendar = .learningDay) -> [Grade: String] {
        intervals(for: state, today: today, retention: retention, calendar: calendar).mapValues(format(days:))
    }

    /// VoiceOver caption per grade ("через 3 дня", "сегодня").
    public static func spokenCaptions(for state: ReviewState?, today: Date, retention: Double = 0.9,
                                      calendar: Calendar = .learningDay) -> [Grade: String] {
        intervals(for: state, today: today, retention: retention, calendar: calendar).mapValues(spoken(days:))
    }

    /// Next interval in days per grade.
    public static func intervals(for state: ReviewState?, today: Date, retention: Double = 0.9,
                                 calendar: Calendar = .learningDay) -> [Grade: Int] {
        let current = state ?? ReviewState(cardID: "")
        var out: [Grade: Int] = [:]
        for grade in Grade.allCases {
            out[grade] = FSRSScheduler.schedule(state: current, grade: grade, today: today,
                                                retention: retention, calendar: calendar).interval
        }
        return out
    }

    /// 0 → "сегодня"; < 30 → "N день/дня/дней"; ≥ 30 → "≈ N мес.".
    public static func format(days: Int) -> String {
        if days <= 0 { return "сегодня" }
        if days >= 30 { return "≈ \(max(1, Int((Double(days) / 30).rounded()))) мес." }
        return RussianPlural.days(days)
    }

    /// Spoken form: "через 3 дня", or "сегодня".
    public static func spoken(days: Int) -> String {
        days <= 0 ? "сегодня" : "через \(format(days: days))"
    }
}
