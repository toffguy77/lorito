import Foundation
import Observation
import Domain

/// «Экзамены DELE и CCSE»: tracks, readiness, countdown and attempt history.
@MainActor
@Observable
public final class ExamsModel: Identifiable {
    public let id = UUID()
    public enum Track: String, CaseIterable, Identifiable, Sendable {
        case deleA2 = "dele-a2", ccse, citizenship
        public var id: String { rawValue }
        public var title: String {
            switch self {
            case .deleA2: "DELE A2"
            case .ccse: "CCSE"
            case .citizenship: "Путь к гражданству"
            }
        }
        /// Exams of the track (citizenship = DELE A2 + CCSE).
        public var exams: [String] { self == .citizenship ? ["dele-a2", "ccse"] : [rawValue] }
    }

    let store: UserDataStore
    let catalog: ContentCatalog
    let purchases: PurchaseService?
    let salesEnabled: Bool
    let analytics: AnalyticsRecording
    private let now: () -> Date
    public private(set) var attempts: [MockAttempt] = []

    public init(store: UserDataStore, catalog: ContentCatalog, purchases: PurchaseService?,
                salesEnabled: Bool = Monetization.salesEnabled,
                analytics: AnalyticsRecording? = nil, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.catalog = catalog
        self.purchases = purchases
        self.salesEnabled = salesEnabled
        self.analytics = analytics ?? AnalyticsService.shared
        self.now = now
        refresh()
    }

    public var exams: ExamCatalog? { catalog.exams }

    /// Reload attempts; close in-progress ones whose time ran out while away.
    public func refresh() {
        var list = (try? store.allMockAttempts()) ?? []
        if let exams {
            for (i, a) in list.enumerated() where a.state == .inProgress {
                guard let def = exams.definition(a.examID) else { continue }
                let closed = MockRun.closeIfExpired(a, def: def, items: items(for: a), now: now())
                if closed != a {
                    list[i] = closed
                    try? store.upsertMockAttempt(closed)
                    analytics.record(.mockExpired(exam: a.examID))
                }
            }
        }
        attempts = list.sorted { $0.startedAt > $1.startedAt }
    }

    /// Entitled to the full exam path: always while sales are off.
    public var isPro: Bool { !salesEnabled || (purchases?.isEntitled(.examPath) ?? false) }

    public func items(for a: MockAttempt) -> [ExamItem] {
        let all = exams?.items(exam: a.examID, form: a.form) ?? []
        // A non-Pro preview attempt (form 0 marker) runs the preview items only.
        return a.form == 0 ? (exams?.items.filter { $0.exam == a.examID && $0.preview && !$0.retired } ?? []) : all
    }

    public func forms(_ exam: String) -> [Int] { exams?.forms(exam: exam) ?? [] }

    /// Pro or preview content; otherwise the paywall (and no attempt).
    public func canStart(_ exam: String, form: Int) -> Bool {
        isPro || (exams?.isPreview(exam: exam, form: form) ?? false)
    }

    /// Starts a mock (non-Pro on a preview form: the preview items only). Nil → show the paywall.
    public func start(_ exam: String, form: Int) -> MockRunnerModel? {
        guard let exams, let def = exams.definition(exam), canStart(exam, form: form) else { return nil }
        let previewOnly = !isPro
        let attempt = MockAttempt(examID: exam, form: previewOnly ? 0 : form, startedAt: now())
        try? store.upsertMockAttempt(attempt)
        analytics.record(.mockStarted(exam: exam, preview: previewOnly))
        let runner = MockRunnerModel(attempt: attempt, definition: def, items: items(for: attempt), store: store,
                                     analytics: analytics, now: now)
        return runner
    }

    public func resume(_ a: MockAttempt) -> MockRunnerModel? {
        guard a.state == .inProgress, let def = exams?.definition(a.examID) else { return nil }
        return MockRunnerModel(attempt: a, definition: def, items: items(for: a), store: store, analytics: analytics, now: now)
    }

    public func readiness(_ exam: String) -> [String: ReadinessLabel] {
        guard let def = exams?.definition(exam) else { return [:] }
        let records = attempts.filter { $0.examID == exam }.map(\.record)
        let reviews = (try? store.allReviews()) ?? []
        if exam == "ccse" {
            let ccse = reviews.filter { $0.kind == .ccse }
            let bank = max(1, exams?.items.filter { $0.exam == "ccse" && !$0.retired }.count ?? 1)
            let mastered = ccse.filter { $0.status == .review && $0.interval >= StatsConstants.longTermIntervalDays }.count
            return ["all": ReadinessCalculator.ccse(mocks: records, itemMastery: Double(mastered) / Double(bank))]
        }
        let cards = Set(exams?.items.filter { $0.exam == exam }.flatMap(\.cards) ?? [])
        let studied = reviews.filter { cards.contains($0.cardID) && $0.status == .review }.count
        return ReadinessCalculator.dele(def, mocks: records, cardMastery: cards.isEmpty ? 0 : Double(studied) / Double(cards.count))
    }

    /// Days to the goal's exam date when its kind matches (from study-goal).
    public func countdown(_ exam: String) -> Int? {
        guard let goal = (try? store.loadSettings())?.exam, goal.kind.rawValue == Self.goalKind(exam) else { return nil }
        return ExamCountdown.learningDaysLeft(goal, today: now())
    }

    static func goalKind(_ exam: String) -> String { exam == "dele-a2" ? ExamKind.deleA2.rawValue : exam }

    /// «Вопросы: Instituto Cervantes, Manual … (edición …)» or nil without a bank.
    public var ccseAttribution: String? {
        let editions = Set(exams?.items.filter { $0.exam == "ccse" && !$0.retired }.compactMap(\.edition) ?? [])
        guard let edition = editions.sorted().last else { return nil }
        return "Вопросы — Instituto Cervantes, «Manual de preparación de la prueba CCSE», edición \(edition)."
    }

    public func delete(_ a: MockAttempt) {
        try? store.deleteMockAttempt(a.id)
        MockRecordingStore().deleteRecordings(attempt: a.id)
        refresh()
    }
}

/// Runs one mock: sections in order with their time limits; answers and ticks
/// persisted on every change; the timer comes from the persisted section start.
@MainActor
@Observable
public final class MockRunnerModel: Identifiable {
    public let id = UUID()
    public private(set) var attempt: MockAttempt
    public let definition: ExamDefinition
    public let items: [ExamItem]
    private let store: UserDataStore
    private let analytics: AnalyticsRecording
    private let now: () -> Date

    init(attempt: MockAttempt, definition: ExamDefinition, items: [ExamItem], store: UserDataStore,
         analytics: AnalyticsRecording, now: @escaping () -> Date) {
        self.attempt = attempt
        self.definition = definition
        self.items = items
        self.store = store
        self.analytics = analytics
        self.now = now
        skipEmptySections()
    }

    public var isFinished: Bool { attempt.state != .inProgress }
    public var section: ExamSection? {
        definition.sections.indices.contains(attempt.sectionIndex) ? definition.sections[attempt.sectionIndex] : nil
    }
    public var sectionItems: [ExamItem] { items.filter { $0.section == section?.id } }

    public func remaining(at date: Date? = nil) -> TimeInterval {
        guard let section else { return 0 }
        return MockTimer.remaining(minutes: section.minutes, startedAt: attempt.sectionStartedAt, now: date ?? now())
    }

    public func answer(_ item: ExamItem, _ option: String) {
        guard !isFinished else { return }
        attempt.answers[item.id] = option
        save()
    }

    public func toggleRubric(_ item: ExamItem, _ index: Int) {
        guard !isFinished else { return }
        var ticks = Set(attempt.rubricTicks[item.id] ?? [])
        if ticks.contains(index) { ticks.remove(index) } else { ticks.insert(index) }
        attempt.rubricTicks[item.id] = ticks.sorted()
        save()
    }

    /// Time check (call on a timer tick / foreground): an expired section is submitted as is.
    public func tick() {
        guard !isFinished, remaining() <= 0 else { return }
        submitSection(expired: true)
    }

    public func submitSection(expired: Bool = false) {
        guard !isFinished else { return }
        if expired {
            attempt = MockRun.complete(attempt, def: definition, items: items, now: now(), expired: true)
            analytics.record(.mockExpired(exam: attempt.examID))
        } else {
            attempt = MockRun.submitSection(attempt, def: definition, items: items, now: now())
            skipEmptySections()
            if attempt.state == .completed {
                analytics.record(.mockCompleted(exam: attempt.examID, passed: result?.passed ?? false))
            }
        }
        save()
    }

    public func abandon() {
        guard !isFinished else { return }
        attempt.state = .abandoned
        attempt.finishedAt = now()
        analytics.record(.mockAbandoned(exam: attempt.examID))
        save()
    }

    public var result: MockResult? { attempt.state == .completed ? MockRun.result(attempt, def: definition) : nil }

    /// Grammar cards behind wrong answers, most frequent first.
    public var weakestCards: [String] {
        var counts: [String: Int] = [:]
        for item in items where !item.isProductive && attempt.answers[item.id] != item.correctAnswer {
            for c in item.cards { counts[c, default: 0] += 1 }
        }
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(5).map(\.key)
    }

    /// Preview runs contain only some sections: skip the empty ones.
    private func skipEmptySections() {
        while attempt.state == .inProgress, section != nil, sectionItems.isEmpty {
            attempt = MockRun.submitSection(attempt, def: definition, items: items, now: now())
        }
    }

    private func save() { try? store.upsertMockAttempt(attempt) }
}
