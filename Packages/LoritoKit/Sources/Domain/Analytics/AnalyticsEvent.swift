import Foundation

/// Onboarding steps, in order.
public enum OnboardingStepName: String, Codable, Sendable, CaseIterable {
    case level, themes, reminders
}

/// Exercise types as analytics values (no content).
public enum ExerciseTypeName: String, Codable, Sendable, CaseIterable {
    case multipleChoice, fillInTheBlank, matching, wordOrder, pictureMatching, freeResponse

    public init(_ kind: ExerciseKind) {
        switch kind {
        case .multipleChoice: self = .multipleChoice
        case .fillInTheBlank: self = .fillInTheBlank
        case .matching: self = .matching
        case .wordOrder: self = .wordOrder
        case .pictureMatching: self = .pictureMatching
        case .freeResponse: self = .freeResponse
        }
    }
}

/// The closed, anonymous product-event taxonomy. Payloads are enums, ints and
/// bools only — never item ids, text or personal data. New events are added
/// only by an ADDED requirement in the `product-analytics` capability.
public enum AnalyticsEvent: Codable, Sendable, Hashable {
    case onboardingStep(OnboardingStepName)
    case onboardingCompleted
    case sessionStarted(due: Int, new: Int)
    case sessionCompleted(items: Int, firstTryPercent: Int)
    case itemGraded(kind: ItemKind, grade: Grade, revealed: Bool)
    case exerciseAnswered(type: ExerciseTypeName, correct: Bool)
    case reminderOpened
    case streakExtended(length: Int)
    case streakLost(previous: Int)

    public var name: String {
        switch self {
        case .onboardingStep: return "onboardingStep"
        case .onboardingCompleted: return "onboardingCompleted"
        case .sessionStarted: return "sessionStarted"
        case .sessionCompleted: return "sessionCompleted"
        case .itemGraded: return "itemGraded"
        case .exerciseAnswered: return "exerciseAnswered"
        case .reminderOpened: return "reminderOpened"
        case .streakExtended: return "streakExtended"
        case .streakLost: return "streakLost"
        }
    }

    public var parameters: [String: String] {
        switch self {
        case .onboardingStep(let step): return ["step": step.rawValue]
        case .onboardingCompleted, .reminderOpened: return [:]
        case .sessionStarted(let due, let new): return ["due": "\(due)", "new": "\(new)"]
        case .sessionCompleted(let items, let pct): return ["items": "\(items)", "firstTryPercent": "\(pct)"]
        case .itemGraded(let kind, let grade, let revealed):
            return ["kind": kind.rawValue, "grade": grade.rawValue, "revealed": "\(revealed)"]
        case .exerciseAnswered(let type, let correct): return ["type": type.rawValue, "correct": "\(correct)"]
        case .streakExtended(let length): return ["length": "\(length)"]
        case .streakLost(let previous): return ["previous": "\(previous)"]
        }
    }
}

/// Experiments whose arms events may carry (closed set — no free text).
public enum Experiment: String, Codable, Sendable, CaseIterable {
    case firstSessionImmediately
}

public enum ExperimentVariant: String, Codable, Sendable, CaseIterable {
    case a, b
}

/// One recorded event with its time and optional experiment arm.
public struct AnalyticsRecord: Codable, Sendable, Hashable {
    public let event: AnalyticsEvent
    public let date: Date
    public let experiment: Experiment?
    public let variant: ExperimentVariant?

    public init(event: AnalyticsEvent, date: Date, experiment: Experiment? = nil, variant: ExperimentVariant? = nil) {
        self.event = event
        self.date = date
        self.experiment = experiment
        self.variant = variant
    }

    public var name: String { event.name }

    public var parameters: [String: String] {
        var p = event.parameters
        if let experiment { p["experiment"] = experiment.rawValue }
        if let variant { p["variant"] = variant.rawValue }
        return p
    }
}

/// Delivers batches to an analytics provider. The app target injects the
/// concrete sink; tests and previews use a recording or no-op sink.
public protocol AnalyticsSink: Sendable {
    func send(_ batch: [AnalyticsRecord]) async throws
    /// Opt-out: tear down any provider state (no further sends follow).
    func stop() async
}

public extension AnalyticsSink {
    func stop() async {}
}

/// Drops everything (tests, previews, opted-out or unconfigured builds).
public struct NoOpAnalyticsSink: AnalyticsSink {
    public init() {}
    public func send(_ batch: [AnalyticsRecord]) async throws {}
}

/// Bounded on-device queue: append, cap (oldest dropped), batch, age-out. Pure.
public struct EventQueue: Codable, Sendable, Equatable {
    public static let defaultCap = 2000
    public static let maxAge: TimeInterval = 30 * 86_400

    public private(set) var records: [AnalyticsRecord] = []
    public let cap: Int

    public init(cap: Int = EventQueue.defaultCap, records: [AnalyticsRecord] = []) {
        self.cap = cap
        self.records = Array(records.suffix(cap))
    }

    public mutating func append(_ record: AnalyticsRecord) {
        records.append(record)
        if records.count > cap { records.removeFirst(records.count - cap) }
    }

    public func nextBatch(size: Int) -> [AnalyticsRecord] { Array(records.prefix(max(0, size))) }

    public mutating func removeFirst(_ count: Int) { records.removeFirst(min(count, records.count)) }

    public mutating func discardExpired(now: Date) {
        records.removeAll { now.timeIntervalSince($0.date) > Self.maxAge }
    }

    public mutating func removeAll() { records.removeAll() }
}

/// A streak is lost when nothing happens, so the loss is detected on the next
/// launch by comparing the last reported streak with the computed one.
public enum StreakLossDetector {
    /// The event to emit (at most once per loss) and the value to store as the
    /// new "last reported" streak.
    public static func check(lastReported: Int?, current: Int) -> (event: AnalyticsEvent?, report: Int) {
        if let last = lastReported, last > 0, current == 0 {
            return (.streakLost(previous: last), 0)
        }
        return (nil, current)
    }
}
