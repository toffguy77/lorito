import Foundation

/// Pure, deterministic SM-2 variant. Given a review state, a grade, and an
/// injected "today", returns the next review state. No I/O, no ambient clock.
public enum SpacedRepetitionScheduler {

    /// A fixed calendar so day math is deterministic regardless of host timezone.
    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    public static func schedule(state: ReviewState, grade: Grade, today: Date) -> ReviewState {
        // Suspended cards are excluded from scheduling: applying a grade is a no-op.
        guard state.status != .suspended else { return state }

        var ease = state.easeFactor
        var reps = state.repetitions
        var interval = state.interval
        var status = state.status

        switch grade {
        case .again:
            ease = clampEase(ease + SRSConstants.againEaseDelta)
            reps = 0
            status = .learning
            interval = SRSConstants.relearnInterval

        case .hard:
            ease = clampEase(ease + SRSConstants.hardEaseDelta)
            switch state.status {
            case .new:
                reps = 1
                interval = SRSConstants.firstIntervalHard
                status = .learning
            case .learning:
                interval = max(1, SRSConstants.firstIntervalHard)
                status = .learning
            case .review, .suspended:
                reps += 1
                interval = max(1, Int((Double(state.interval) * SRSConstants.hardFactor).rounded()))
                status = .review
            }

        case .good:
            ease = clampEase(ease + SRSConstants.goodEaseDelta)
            switch state.status {
            case .new:
                reps = 1
                interval = SRSConstants.firstIntervalGood
                status = .learning
            case .learning:
                reps += 1
                interval = max(1, Int((Double(max(state.interval, 1)) * ease).rounded()))
                status = .review
            case .review, .suspended:
                reps += 1
                interval = max(1, Int((Double(state.interval) * ease).rounded()))
                status = .review
            }

        case .easy:
            ease = clampEase(ease + SRSConstants.easyEaseDelta)
            switch state.status {
            case .new:
                reps = 1
                interval = SRSConstants.firstIntervalEasy
                status = .review
            case .learning:
                reps += 1
                interval = max(1, Int((Double(max(state.interval, 1)) * ease * SRSConstants.easyBonus).rounded()))
                status = .review
            case .review, .suspended:
                reps += 1
                interval = max(1, Int((Double(state.interval) * ease * SRSConstants.easyBonus).rounded()))
                status = .review
            }
        }

        return ReviewState(
            cardID: state.cardID,
            easeFactor: ease,
            interval: interval,
            repetitions: reps,
            dueDate: dueDate(from: today, interval: interval),
            lastGrade: grade.rawValue,
            status: status
        )
    }

    /// "today" advanced by `interval` whole days.
    public static func dueDate(from today: Date, interval: Int) -> Date {
        let start = calendar.startOfDay(for: today)
        return calendar.date(byAdding: .day, value: interval, to: start) ?? start
    }

    private static func clampEase(_ value: Double) -> Double {
        max(SRSConstants.easeFloor, value)
    }
}
