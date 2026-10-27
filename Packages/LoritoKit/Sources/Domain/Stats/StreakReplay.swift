import Foundation

public enum StreakConstants {
    public static let freezeEarnEvery = 7
    public static let maxFreezes = 2
    public static let revivalDays = 3
    public static let revivalWindowDays = 7
    public static let revivalCooldownDays = 30
    public static let minRevivableStreak = 2
}

public enum RevivalStatus: Sendable, Hashable {
    case none
    /// `daysDone` of `revivalDays` consecutive study days inside the window ending at `deadline`.
    case inProgress(daysDone: Int, deadline: Date, lost: Int)
    /// Restored today or yesterday.
    case completed(lost: Int)
}

/// Streak state replayed from the study log (streak-protection).
public struct StreakReport: Sendable, Hashable {
    public let current: Int
    public let best: Int
    public let freezes: Int
    public let frozenYesterday: Bool
    public let revival: RevivalStatus
}

extension StatsCalculator {
    /// Replays learning days from the first study day to today: a day is
    /// studied with ≥ 1 grade event; one freeze is earned per 7 consecutive
    /// studied days (max 2) and consumed by each missed past day of an active
    /// run; a lost run (≥ 2) is revived by 3 consecutive study days within
    /// the 7 days after the loss, at most once per 30 days. Today is savable.
    public static func streak(events: [StudyEvent], today: Date, calendar: Calendar = .learningDay) -> StreakReport {
        let studied = Set(events.filter { $0.grade != nil }.map { calendar.startOfDay(for: $0.date) })
        let today0 = calendar.startOfDay(for: today)
        guard let first = studied.min(), first <= today0 else {
            return StreakReport(current: 0, best: 0, freezes: 0, frozenYesterday: false, revival: .none)
        }
        func offset(_ day: Date) -> Int { calendar.dateComponents([.day], from: first, to: day).day ?? 0 }
        let todayIndex = offset(today0)
        let studiedIdx = Set(studied.map(offset))

        var run = 0, earn = 0, stock = 0, best = 0
        var frozen: Set<Int> = []
        var lastRevivedLoss: Int?
        // A pending revival: loss day, lost length, and the new run's length so far.
        var pending: (loss: Int, lost: Int)?
        var newRun = 0
        var completedOn: (day: Int, lost: Int)?

        for i in 0...todayIndex {
            if studiedIdx.contains(i) {
                if let p = pending, i <= p.loss + StreakConstants.revivalWindowDays {
                    newRun += 1
                    run = newRun
                    if newRun == StreakConstants.revivalDays {
                        run = p.lost + newRun
                        lastRevivedLoss = p.loss
                        completedOn = (i, p.lost)
                        pending = nil
                    }
                } else {
                    if let p = pending, i > p.loss + StreakConstants.revivalWindowDays { pending = nil }
                    run += 1
                }
                earn += 1
                if earn == StreakConstants.freezeEarnEvery {
                    earn = 0
                    stock = min(stock + 1, StreakConstants.maxFreezes)
                }
                best = max(best, run)
            } else if i < todayIndex {
                if run > 0, stock > 0 {
                    stock -= 1
                    frozen.insert(i)
                } else if run > 0 {
                    // Loss. A break inside a pending revival only restarts its new run.
                    if pending != nil {
                        newRun = 0
                    } else if run >= StreakConstants.minRevivableStreak,
                              lastRevivedLoss.map({ i - $0 >= StreakConstants.revivalCooldownDays }) ?? true {
                        pending = (i, run)
                        newRun = 0
                    }
                    run = 0
                    earn = 0
                }
                if let p = pending, i >= p.loss + StreakConstants.revivalWindowDays { pending = nil }
            }
        }

        let revival: RevivalStatus
        if let p = pending, todayIndex <= p.loss + StreakConstants.revivalWindowDays {
            let deadline = calendar.date(byAdding: .day, value: p.loss + StreakConstants.revivalWindowDays, to: first) ?? today0
            revival = .inProgress(daysDone: newRun, deadline: deadline, lost: p.lost)
        } else if let c = completedOn, todayIndex - c.day <= 1 {
            revival = .completed(lost: c.lost)
        } else {
            revival = .none
        }
        return StreakReport(current: run, best: best, freezes: stock, frozenYesterday: frozen.contains(todayIndex - 1),
                            revival: revival)
    }
}
