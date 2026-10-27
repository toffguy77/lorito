import Foundation
import Domain
import DesignSystem

extension StudyGrade {
    /// The design-system grade maps 1:1 to the Domain grade (same cases).
    var domain: Grade { Grade(rawValue: rawValue) ?? .good }
}

extension Grade {
    var studyGrade: StudyGrade { StudyGrade(rawValue: rawValue) ?? .good }
}

/// The learning-day calendar, so "graded today" and due comparisons agree with
/// the planner and `DueSelection`.
enum StudyDay {
    static var calendar: Calendar { .learningDay }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }
}
