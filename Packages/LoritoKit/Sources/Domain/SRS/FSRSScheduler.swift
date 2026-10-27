import Foundation

/// FSRS-6 model parameters.
public struct FSRSParameters: Sendable, Hashable {
    public let w: [Double]

    /// The 21 FSRS-6 defaults, copied verbatim from py-fsrs 6.3.2
    /// (`fsrs/scheduler.py`, `DEFAULT_PARAMETERS`;
    /// https://github.com/open-spaced-repetition/py-fsrs).
    public static let defaults = FSRSParameters(w: [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796,
        1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ])

    /// No interval exceeds this many days.
    public static let maxInterval = 365

    /// Curve exponent (−w₂₀) and the factor that makes R(S, S) = 0.9.
    var decay: Double { -w[20] }
    var factor: Double { pow(0.9, 1 / decay) - 1 }
}

/// FSRS memory state of one card.
public struct FSRSMemory: Sendable, Hashable {
    public var stability: Double
    public var difficulty: Double
    public var lastReviewDate: Date
}

/// Pure, deterministic FSRS-6 scheduler with day granularity: no I/O, no
/// ambient clock, no fuzz, no sub-day learning steps. Only the first grade of
/// a learning day reaches it (`GradingService`), so elapsed time is whole
/// days. `SpacedRepetitionScheduler` (SM-2) is kept, unused, for rollback.
public enum FSRSScheduler {
    /// `ReviewState.schedulerVersion` written by this scheduler.
    public static let version = 2

    static let p = FSRSParameters.defaults
    static let minStability = 0.001

    public static func schedule(state: ReviewState, grade: Grade, today: Date, retention: Double = 0.9,
                                calendar: Calendar = .learningDay) -> ReviewState {
        guard state.status != .suspended else { return state }
        let retention = UserSettings.clampRetention(retention)
        let start = calendar.startOfDay(for: today)

        let memory: FSRSMemory? = state.status == .new ? nil : validMemory(state, calendar: calendar)
        let next = nextMemory(memory, grade: grade, today: start, calendar: calendar)

        var reps = state.repetitions
        var status = state.status
        var interval: Int
        if grade == .again {
            reps = 0
            status = .learning
            interval = 0
        } else {
            interval = orderedIntervals(memory, today: start, retention: retention, calendar: calendar)[grade] ?? 1
            switch (state.status, grade) {
            case (.new, .easy):
                reps = 1
                status = .review
            case (.new, _):
                reps = 1
                status = .learning
            case (.learning, .hard):
                interval = max(1, interval)
            default:
                reps += 1
                status = .review
            }
        }

        let due = SpacedRepetitionScheduler.dueDate(from: start, interval: interval, calendar: calendar)
        var out = state
        out.interval = interval
        out.repetitions = reps
        out.dueDate = due
        out.lastGrade = grade.rawValue
        out.status = status
        out.stability = next.stability
        out.difficulty = next.difficulty
        out.lastReviewDate = next.lastReviewDate
        out.schedulerVersion = version
        out.fsrsDueDate = due
        return out
    }

    /// An FSRS state is trusted only if FSRS wrote it and no older (SM-2)
    /// build has rescheduled the card since.
    public static func hasValidMemory(_ state: ReviewState) -> Bool {
        guard state.schedulerVersion == version, state.stability != nil, state.difficulty != nil,
              state.lastReviewDate != nil, let fsrsDue = state.fsrsDueDate else { return false }
        return abs(fsrsDue.timeIntervalSince(state.dueDate)) < 1
    }

    /// Memory state to grade from: the stored one if valid, else migrated from
    /// the current SM-2 fields (stale FSRS fields discarded).
    static func validMemory(_ state: ReviewState, calendar: Calendar) -> FSRSMemory? {
        if hasValidMemory(state), let s = state.stability, let d = state.difficulty, let last = state.lastReviewDate {
            return FSRSMemory(stability: s, difficulty: d, lastReviewDate: last)
        }
        var sm2 = state
        sm2.stability = nil
        sm2.difficulty = nil
        sm2.lastReviewDate = nil
        return SM2Migration.memoryState(from: sm2, calendar: calendar)
    }

    // MARK: Intervals

    /// Whole days until retrievability falls to `retention`, in [1, maxInterval].
    /// With retention 0.9 this is round(stability).
    public static func interval(stability: Double, retention: Double) -> Int {
        let raw = stability / p.factor * (pow(retention, 1 / p.decay) - 1)
        guard raw.isFinite else { return FSRSParameters.maxInterval }
        return min(max(Int(raw.rounded()), 1), FSRSParameters.maxInterval)
    }

    /// Passing-grade intervals with the ordering guard: hard ≤ good, and
    /// easy ≥ good + 1 unless good is at the cap (then easy == good).
    static func orderedIntervals(_ memory: FSRSMemory?, today: Date, retention: Double,
                                 calendar: Calendar) -> [Grade: Int] {
        func raw(_ g: Grade) -> Int {
            interval(stability: nextMemory(memory, grade: g, today: today, calendar: calendar).stability,
                     retention: retention)
        }
        let good = raw(.good)
        let hard = min(raw(.hard), good)
        let easy = min(max(raw(.easy), good + 1), FSRSParameters.maxInterval)
        return [.hard: hard, .good: good, .easy: easy]
    }

    // MARK: Memory model (FSRS-6)

    static func nextMemory(_ memory: FSRSMemory?, grade: Grade, today: Date, calendar: Calendar) -> FSRSMemory {
        guard let m = memory else {
            return FSRSMemory(stability: initialStability(grade), difficulty: initialDifficulty(grade, clamp: true),
                              lastReviewDate: today)
        }
        let t = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: m.lastReviewDate),
                                               to: today).day ?? 0)
        let r = retrievability(elapsedDays: Double(t), stability: m.stability)
        let s = grade == .again
            ? nextForgetStability(difficulty: m.difficulty, stability: m.stability, retrievability: r)
            : nextRecallStability(difficulty: m.difficulty, stability: m.stability, retrievability: r, grade: grade)
        return FSRSMemory(stability: max(s, minStability), difficulty: nextDifficulty(m.difficulty, grade: grade),
                          lastReviewDate: today)
    }

    /// R(t, S) = (1 + factor · t / S)^decay.
    public static func retrievability(elapsedDays t: Double, stability s: Double) -> Double {
        pow(1 + p.factor * t / s, p.decay)
    }

    static func rating(_ g: Grade) -> Double {
        switch g {
        case .again: 1
        case .hard: 2
        case .good: 3
        case .easy: 4
        }
    }

    static func initialStability(_ g: Grade) -> Double {
        max(p.w[Int(rating(g)) - 1], minStability)
    }

    static func initialDifficulty(_ g: Grade, clamp: Bool) -> Double {
        let d = p.w[4] - exp(p.w[5] * (rating(g) - 1)) + 1
        return clamp ? clampDifficulty(d) : d
    }

    static func nextDifficulty(_ d: Double, grade: Grade) -> Double {
        let delta = -p.w[6] * (rating(grade) - 3)
        let damped = d + (10 - d) * delta / 9
        let reverted = p.w[7] * initialDifficulty(.easy, clamp: false) + (1 - p.w[7]) * damped
        return clampDifficulty(reverted)
    }

    public static func nextRecallStability(difficulty d: Double, stability s: Double, retrievability r: Double,
                                           grade: Grade) -> Double {
        let hardPenalty = grade == .hard ? p.w[15] : 1
        let easyBonus = grade == .easy ? p.w[16] : 1
        return s * (1 + exp(p.w[8]) * (11 - d) * pow(s, -p.w[9]) * (exp((1 - r) * p.w[10]) - 1)
            * hardPenalty * easyBonus)
    }

    static func nextForgetStability(difficulty d: Double, stability s: Double, retrievability r: Double) -> Double {
        let longTerm = p.w[11] * pow(d, -p.w[12]) * (pow(s + 1, p.w[13]) - 1) * exp((1 - r) * p.w[14])
        let shortTerm = s / exp(p.w[17] * p.w[18])
        return min(longTerm, shortTerm)
    }

    static func clampDifficulty(_ d: Double) -> Double { min(max(d, 1), 10) }
}

/// Pure, lazy conversion of an SM-2 review state into an FSRS memory state,
/// applied the first time an unmigrated card is graded.
public enum SM2Migration {
    /// `nil` for `new` and `suspended` cards (nothing to migrate). Stability =
    /// max(interval, 1) days (SM-2 reviews land near the 90 % point);
    /// difficulty from ease; last review = dueDate − interval when absent
    /// (an approximation: the day the SM-2 interval was set).
    public static func memoryState(from state: ReviewState, calendar: Calendar = .learningDay) -> FSRSMemory? {
        guard state.status == .review || state.status == .learning else { return nil }
        let last = state.lastReviewDate
            ?? calendar.date(byAdding: .day, value: -state.interval, to: calendar.startOfDay(for: state.dueDate))
            ?? state.dueDate
        return FSRSMemory(stability: Double(max(state.interval, 1)), difficulty: difficulty(fromEase: state.easeFactor),
                          lastReviewDate: last)
    }

    /// Linear map ease 2.5 → 5, 1.3 → 9, clamped to 1…10.
    public static func difficulty(fromEase ease: Double) -> Double {
        FSRSScheduler.clampDifficulty(5 + (2.5 - ease) * (4 / 1.2))
    }
}
