// Named constants for the SM-2 variant. No magic numbers in the scheduler.
public enum SRSConstants {
    public static let easeFloor: Double = 1.3
    public static let defaultEase: Double = 2.5

    // Ease deltas per grade.
    public static let againEaseDelta: Double = -0.20
    public static let hardEaseDelta: Double = -0.15
    public static let goodEaseDelta: Double = 0.0
    public static let easyEaseDelta: Double = 0.15

    // First-review intervals (days) for a `new` card.
    public static let firstIntervalHard: Int = 1
    public static let firstIntervalGood: Int = 1
    public static let firstIntervalEasy: Int = 4

    // Relearn interval (days) after `again` — due the same day.
    public static let relearnInterval: Int = 0

    // Review-growth modifiers.
    public static let hardFactor: Double = 1.2   // hard grows slower than ease
    public static let easyBonus: Double = 1.3    // extra multiplier on top of ease for easy
}
