import Foundation
import Domain
import DesignSystem

extension StudyGrade {
    /// The design-system grade maps 1:1 to the Domain SM-2 grade (same cases).
    var domain: Grade { Grade(rawValue: rawValue) ?? .good }
}

/// A UTC day calendar matching the one the planner and `DueSelection` use, so
/// "graded today" and due comparisons agree across the app.
enum StudyDay {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }
}
