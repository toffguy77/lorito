import Foundation

/// Minutes-left estimate for a running session (Live Activity).
public enum SessionPace {
    public static let defaultSecondsPerCard: Double = 45

    /// remaining × median seconds per card graded this session (default 45 s),
    /// rounded up to whole minutes; at least 1 while cards remain.
    public static func minutesLeft(remaining: Int, secondsPerCard: [Double]) -> Int {
        guard remaining > 0 else { return 0 }
        let pace = median(secondsPerCard) ?? defaultSecondsPerCard
        return max(1, Int((Double(remaining) * pace / 60).rounded(.up)))
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
