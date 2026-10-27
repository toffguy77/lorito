import Foundation

/// A mock exam attempt (synced). Answers and rubric ticks are kept per item.
public struct MockAttempt: Codable, Sendable, Hashable, Identifiable {
    public enum State: String, Codable, Sendable { case inProgress, completed, abandoned }

    public var id: UUID
    public var examID: String
    public var form: Int
    public var startedAt: Date
    /// Index of the running section and when it started (timer source of truth).
    public var sectionIndex: Int
    public var sectionStartedAt: Date
    public var answers: [String: String]
    public var rubricTicks: [String: [Int]]
    public var state: State
    public var finishedAt: Date?
    /// Scaled points per section once completed.
    public var sectionPoints: [String: Double]
    /// Closed because time ran out (incl. while the app wasn't running).
    public var expired: Bool

    public init(id: UUID = UUID(), examID: String, form: Int, startedAt: Date, sectionIndex: Int = 0,
                sectionStartedAt: Date? = nil, answers: [String: String] = [:], rubricTicks: [String: [Int]] = [:],
                state: State = .inProgress, finishedAt: Date? = nil, sectionPoints: [String: Double] = [:],
                expired: Bool = false) {
        self.id = id
        self.examID = examID
        self.form = form
        self.startedAt = startedAt
        self.sectionIndex = sectionIndex
        self.sectionStartedAt = sectionStartedAt ?? startedAt
        self.answers = answers
        self.rubricTicks = rubricTicks
        self.state = state
        self.finishedAt = finishedAt
        self.sectionPoints = sectionPoints
        self.expired = expired
    }

    public var record: MockRecord {
        MockRecord(examID: examID, completed: state == .completed, abandoned: state == .abandoned,
                   sectionFractions: sectionPoints)
    }
}

/// Pure attempt transitions.
public enum MockRun {
    /// Finish the running section and move on (or complete the attempt).
    public static func submitSection(_ a: MockAttempt, def: ExamDefinition, items: [ExamItem], now: Date,
                                     expired: Bool = false) -> MockAttempt {
        var a = a
        guard a.state == .inProgress else { return a }
        if a.sectionIndex + 1 < def.sections.count && !expired {
            a.sectionIndex += 1
            a.sectionStartedAt = now
            return a
        }
        return complete(a, def: def, items: items, now: now, expired: expired)
    }

    /// Score with what was answered (unanswered = incorrect).
    public static func complete(_ a: MockAttempt, def: ExamDefinition, items: [ExamItem], now: Date,
                                expired: Bool = false) -> MockAttempt {
        var a = a
        var rubric: [String: Double] = [:]
        for item in items where item.isProductive {
            rubric[item.id] = RubricScore(rubric: item.rubric, ticked: Set(a.rubricTicks[item.id] ?? [])).points
        }
        let points = MockScorer.sectionPoints(def, items: items, answers: a.answers, rubricPoints: rubric)
        // Fractions per section (readiness input) stored as points / max.
        a.sectionPoints = Dictionary(uniqueKeysWithValues: def.sections.map { s in
            (s.id, s.maxPoints > 0 ? (points[s.id] ?? 0) / s.maxPoints : 0)
        })
        a.state = .completed
        a.finishedAt = now
        a.expired = expired
        return a
    }

    /// On launch / foreground: an in-progress attempt whose section ran out is closed.
    public static func closeIfExpired(_ a: MockAttempt, def: ExamDefinition, items: [ExamItem], now: Date) -> MockAttempt {
        guard a.state == .inProgress, def.sections.indices.contains(a.sectionIndex) else { return a }
        let section = def.sections[a.sectionIndex]
        guard MockTimer.isExpired(minutes: section.minutes, startedAt: a.sectionStartedAt, now: now) else { return a }
        return complete(a, def: def, items: items, now: now, expired: true)
    }

    public static func result(_ a: MockAttempt, def: ExamDefinition) -> MockResult {
        MockScorer.score(def, sectionPoints: Dictionary(uniqueKeysWithValues: def.sections.map {
            ($0.id, (a.sectionPoints[$0.id] ?? 0) * $0.maxPoints)
        }))
    }
}
