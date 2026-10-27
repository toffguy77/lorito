import Foundation

/// A scored part of an exam (DELE: reading, listening, writing, speaking).
public struct ExamSection: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let minutes: Int
    public let maxPoints: Double
    /// Writing / speaking: self-assessed with a rubric.
    public let productive: Bool
    /// Speaking preparation time before the timed part.
    public let prepMinutes: Int?

    public init(id: String, title: String, minutes: Int, maxPoints: Double, productive: Bool, prepMinutes: Int? = nil) {
        self.id = id
        self.title = title
        self.minutes = minutes
        self.maxPoints = maxPoints
        self.productive = productive
        self.prepMinutes = prepMinutes
    }
}

/// Sections scored together with a pass threshold (DELE groups; CCSE has one).
public struct ScoreGroup: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let sections: [String]
    public let passPoints: Double

    public init(id: String, title: String, sections: [String], passPoints: Double) {
        self.id = id
        self.title = title
        self.sections = sections
        self.passPoints = passPoints
    }
}

/// An exam as content data: timings and thresholds carry `verifiedOn`.
public struct ExamDefinition: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let verifiedOn: String
    public let sections: [ExamSection]
    public let groups: [ScoreGroup]
    /// Short Russian description of format and pass rule.
    public let summary: String?
    public let fee: String?

    public init(id: String, title: String, verifiedOn: String, sections: [ExamSection], groups: [ScoreGroup],
                summary: String? = nil, fee: String? = nil) {
        self.id = id
        self.title = title
        self.verifiedOn = verifiedOn
        self.sections = sections
        self.groups = groups
        self.summary = summary
        self.fee = fee
    }
}

public struct RubricItem: Codable, Sendable, Hashable {
    public let text: String
    public let points: Double
    public init(text: String, points: Double) {
        self.text = text
        self.points = points
    }
}

/// One exam question or task.
public struct ExamItem: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: Codable, Sendable, Hashable {
        /// Multiple choice; true/false is two options.
        case choice(options: [String], answer: String)
        /// A listening question: `script` is spoken, then a choice.
        case listeningTask(script: String, options: [String], answer: String)
        case writingTask(prompt: String, rubric: [RubricItem])
        case speakingTask(prompt: String, prepSeconds: Int, rubric: [RubricItem])
    }

    public let id: String
    public let exam: String
    public let section: String
    public let points: Double
    public let kind: Kind
    /// Shown as the question text (choice items) or context (tasks).
    public let text: String
    /// Russian explanation after answering.
    public let explanation: String
    /// Mock form the item belongs to (DELE mocks, CCSE forms).
    public let form: Int
    /// Free preview content (content flag, not a counter).
    public let preview: Bool
    /// Grammar cards the item practises (DELE) — weakest cards on results.
    public let cards: [String]
    /// CCSE attribution.
    public let source: String?
    public let edition: String?
    public let retired: Bool

    public init(id: String, exam: String, section: String, points: Double = 1, kind: Kind, text: String = "",
                explanation: String = "", form: Int = 1, preview: Bool = false, cards: [String] = [],
                source: String? = nil, edition: String? = nil, retired: Bool = false) {
        self.id = id
        self.exam = exam
        self.section = section
        self.points = points
        self.kind = kind
        self.text = text
        self.explanation = explanation
        self.form = form
        self.preview = preview
        self.cards = cards
        self.source = source
        self.edition = edition
        self.retired = retired
    }

    public var isProductive: Bool {
        switch kind {
        case .writingTask, .speakingTask: true
        default: false
        }
    }

    public var rubric: [RubricItem] {
        switch kind {
        case .writingTask(_, let r), .speakingTask(_, _, let r): r
        default: []
        }
    }

    public var correctAnswer: String? {
        switch kind {
        case .choice(_, let a), .listeningTask(_, _, let a): a
        default: nil
        }
    }
}

/// The `exams` section of the content bundle.
public struct ExamCatalog: Codable, Sendable, Hashable {
    public let definitions: [ExamDefinition]
    public let items: [ExamItem]

    public init(definitions: [ExamDefinition], items: [ExamItem]) {
        self.definitions = definitions
        self.items = items
    }

    public func definition(_ id: String) -> ExamDefinition? { definitions.first { $0.id == id } }
    public func items(exam: String, form: Int) -> [ExamItem] { items.filter { $0.exam == exam && $0.form == form && !$0.retired } }
    public func forms(exam: String) -> [Int] { Array(Set(items.filter { $0.exam == exam && !$0.retired }.map(\.form))).sorted() }
    public func isPreview(exam: String, form: Int) -> Bool { items(exam: exam, form: form).contains(where: \.preview) }
}

// MARK: Scoring

public struct MockResult: Sendable, Hashable {
    public let sectionPoints: [String: Double]
    public let groupPoints: [String: Double]
    public let passed: Bool
    public let failingGroups: [String]
}

/// Pure mock scoring: each section scaled to its maximum; every group must
/// reach its pass points. Unanswered questions are incorrect.
public enum MockScorer {
    public static func sectionPoints(_ def: ExamDefinition, items: [ExamItem], answers: [String: String],
                                     rubricPoints: [String: Double]) -> [String: Double] {
        var out: [String: Double] = [:]
        for section in def.sections {
            let inSection = items.filter { $0.section == section.id }
            let possible = inSection.reduce(0.0) { $0 + ($1.isProductive ? $1.rubric.reduce(0) { $0 + $1.points } : $1.points) }
            let earned = inSection.reduce(0.0) { sum, item in
                if item.isProductive { return sum + min(rubricPoints[item.id] ?? 0, item.rubric.reduce(0) { $0 + $1.points }) }
                return sum + (answers[item.id] != nil && answers[item.id] == item.correctAnswer ? item.points : 0)
            }
            out[section.id] = possible > 0 ? (earned / possible * section.maxPoints).rounded(toPlaces: 2) : 0
        }
        return out
    }

    public static func score(_ def: ExamDefinition, sectionPoints: [String: Double]) -> MockResult {
        var groupPoints: [String: Double] = [:]
        var failing: [String] = []
        for g in def.groups {
            let total = g.sections.reduce(0) { $0 + (sectionPoints[$1] ?? 0) }
            groupPoints[g.id] = total
            if total < g.passPoints { failing.append(g.id) }
        }
        return MockResult(sectionPoints: sectionPoints, groupPoints: groupPoints, passed: failing.isEmpty,
                          failingGroups: failing)
    }
}

extension Double {
    func rounded(toPlaces p: Int) -> Double {
        let f = pow(10, Double(p))
        return (self * f).rounded() / f
    }
}

/// Self-assessed rubric: ticked items → points.
public struct RubricScore: Sendable, Hashable {
    public let points: Double
    public let isSelfAssessed = true

    public init(rubric: [RubricItem], ticked: Set<Int>) {
        points = ticked.filter { rubric.indices.contains($0) }.reduce(0) { $0 + rubric[$1].points }
    }
}

/// Section time from the persisted start and an injected now (backgrounding never pauses).
public enum MockTimer {
    public static func remaining(minutes: Int, startedAt: Date, now: Date) -> TimeInterval {
        max(0, TimeInterval(minutes * 60) - now.timeIntervalSince(startedAt))
    }

    public static func isExpired(minutes: Int, startedAt: Date, now: Date) -> Bool {
        remaining(minutes: minutes, startedAt: startedAt, now: now) <= 0
    }
}

// MARK: Readiness

public enum ReadinessLabel: String, Codable, Sendable, Comparable {
    case tooEarly, borderline, likely

    public var title: String {
        switch self {
        case .likely: "Скорее сдадите"
        case .borderline: "На грани"
        case .tooEarly: "Пока рано"
        }
    }

    public static func < (a: ReadinessLabel, b: ReadinessLabel) -> Bool {
        let order: [ReadinessLabel] = [.tooEarly, .borderline, .likely]
        return order.firstIndex(of: a)! < order.firstIndex(of: b)!
    }

    static func from(_ score: Double) -> ReadinessLabel {
        score >= 0.7 ? .likely : score >= 0.55 ? .borderline : .tooEarly
    }
}

/// A finished (or abandoned) mock as readiness input: section score fractions.
public struct MockRecord: Sendable, Hashable {
    public let examID: String
    public let completed: Bool
    public let abandoned: Bool
    public let sectionFractions: [String: Double]

    public init(examID: String, completed: Bool, abandoned: Bool, sectionFractions: [String: Double]) {
        self.examID = examID
        self.completed = completed
        self.abandoned = abandoned
        self.sectionFractions = sectionFractions
    }
}

/// Pure readiness: the last three complete mocks per part blended with mastery
/// (0.7 / 0.3). A DELE group without any productive-part attempt is capped at
/// «На грани». Abandoned attempts never count. Copy never promises a pass.
public enum ReadinessCalculator {
    public static func dele(_ def: ExamDefinition, mocks: [MockRecord], cardMastery: Double) -> [String: ReadinessLabel] {
        let usable = mocks.filter { $0.completed && !$0.abandoned && $0.examID == def.id }
        var out: [String: ReadinessLabel] = [:]
        for g in def.groups {
            var parts: [Double] = []
            var productiveSeen = false
            for sid in g.sections {
                let scores = usable.compactMap { $0.sectionFractions[sid] }.suffix(3)
                if !scores.isEmpty {
                    parts.append(scores.reduce(0, +) / Double(scores.count))
                    if def.sections.first(where: { $0.id == sid })?.productive == true { productiveSeen = true }
                }
            }
            let mock = parts.isEmpty ? 0 : parts.reduce(0, +) / Double(parts.count)
            var label = ReadinessLabel.from(0.7 * mock + 0.3 * cardMastery)
            if !productiveSeen { label = min(label, .borderline) }
            out[g.id] = label
        }
        return out
    }

    public static func ccse(mocks: [MockRecord], itemMastery: Double) -> ReadinessLabel {
        let scores = mocks.filter { $0.completed && !$0.abandoned && $0.examID == "ccse" }
            .compactMap { $0.sectionFractions.values.first }.suffix(3)
        guard !scores.isEmpty else { return min(.from(itemMastery), .borderline) }
        return .from(0.7 * (scores.reduce(0, +) / Double(scores.count)) + 0.3 * itemMastery)
    }
}
