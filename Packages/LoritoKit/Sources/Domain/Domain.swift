// Domain — pure Swift layer.
//
// This layer holds the core model and (in later changes) the SM-2 scheduler and
// daily-plan composition. It MUST NOT import SwiftUI, SwiftData, or CloudKit so
// it stays unit-testable from the command line and portable across platforms.

/// Namespace marker for the Domain layer.
public enum Domain {
    public static let layer = "Domain"
}
