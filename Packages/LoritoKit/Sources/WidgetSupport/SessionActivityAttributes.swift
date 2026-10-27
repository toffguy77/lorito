#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

/// Live Activity for a running study session (Dynamic Island + Lock Screen).
public struct SessionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// Cards graded so far.
        public var position: Int
        public var total: Int
        /// Estimated minutes left (≥ 1 while cards remain).
        public var minutesLeft: Int

        public init(position: Int, total: Int, minutesLeft: Int) {
            self.position = position
            self.total = total
            self.minutesLeft = minutesLeft
        }
    }

    public init() {}
}
#endif
