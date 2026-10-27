import Foundation
import SwiftData
import Domain

/// SwiftData-backed `UserDataStore`. Maps between Domain value types and the
/// SwiftData @Model records. Use one instance per `ModelContext`.
public final class SwiftDataUserDataStore: UserDataStore {
    private let context: ModelContext
    /// Device-local mirror of celebrated levels: CloudKit resolves a field
    /// conflict by last writer, so the union is restored from here on load and
    /// written back on save (weekly-recap-and-milestones).
    private let localMirror: UserDefaults?
    static let celebratedMirrorKey = "lorito.celebratedLevels.local"

    public init(context: ModelContext, localMirror: UserDefaults? = .standard) {
        self.context = context
        self.localMirror = localMirror
    }

    public convenience init(container: ModelContainer, localMirror: UserDefaults? = .standard) {
        self.init(context: ModelContext(container), localMirror: localMirror)
    }

    private var mirroredCelebrated: String? { localMirror?.string(forKey: Self.celebratedMirrorKey) }

    // MARK: Settings

    public func loadSettings() throws -> UserSettings {
        guard let r = try context.fetch(FetchDescriptor<SettingsRecord>()).first else {
            return .default
        }
        var settings = UserSettings(
            targetLevel: r.targetLevelRaw.flatMap(CEFRLevel.init(rawValue:)),
            selectedThemeIDs: r.selectedThemeIDs,
            dailyNewCardCount: r.dailyNewCardCount,
            remindersEnabled: r.remindersEnabled,
            reminderMinutes: r.reminderMinutes,
            didCompleteOnboarding: r.didCompleteOnboarding,
            spanishVariant: SpanishVariant.decode(r.spanishVariantRaw),
            speechRate: r.speechRateRaw.flatMap(SpeechRate.init(rawValue:)) ?? .normal,
            playAudioWhenSilent: r.playAudioWhenSilent,
            desiredRetention: r.desiredRetention,
            placementKnownLevel: r.placementKnownLevelRaw.flatMap(CEFRLevel.init(rawValue:))
        )
        settings.goalTargetLevel = r.goalTargetLevelRaw.flatMap(CEFRLevel.init(rawValue:))
        settings.goalTargetDate = r.goalTargetDate
        settings.goalStartDate = r.goalStartDate
        settings.goalStartIntroduced = r.goalStartIntroduced
        settings.goalState = r.goalStateRaw.flatMap(GoalState.init(rawValue:))
        settings.examKind = r.examKindRaw.flatMap(ExamKind.init(rawValue:))
        settings.examDate = r.examDate
        settings.examDone = r.examDone
        settings.dailyConjugationCount = r.dailyConjugationCount
        settings.lastRecapWeek = r.lastRecapWeek
        settings.ccseDailyNewLimit = r.ccseDailyNewLimit
        settings.dailyNewWordCount = r.dailyNewWordCount
        settings.selectedDeckIDs = r.selectedDeckIDs
        settings.variantPromptAnswered = r.variantPromptAnswered
        settings.personalWordIDs = r.personalWordIDs
        // Union with this device's mirror (an incoming sync may have dropped levels).
        settings.celebratedLevelsRaw = Self.nonEmpty(CelebratedLevels.merge(r.celebratedLevels, mirroredCelebrated))
        return settings
    }

    public func saveSettings(_ settings: UserSettings) throws {
        let record = try context.fetch(FetchDescriptor<SettingsRecord>()).first ?? {
            let new = SettingsRecord()
            context.insert(new)
            return new
        }()
        record.targetLevelRaw = settings.targetLevel?.rawValue
        record.selectedThemeIDs = settings.selectedThemeIDs
        record.dailyNewCardCount = settings.dailyNewCardCount
        record.remindersEnabled = settings.remindersEnabled
        record.reminderMinutes = settings.reminderMinutes
        record.didCompleteOnboarding = settings.didCompleteOnboarding
        record.spanishVariantRaw = settings.spanishVariant.rawValue
        record.speechRateRaw = settings.speechRate.rawValue
        record.playAudioWhenSilent = settings.playAudioWhenSilent
        record.desiredRetention = settings.desiredRetention
        record.placementKnownLevelRaw = settings.placementKnownLevel?.rawValue
        record.goalTargetLevelRaw = settings.goalTargetLevel?.rawValue
        record.goalTargetDate = settings.goalTargetDate
        record.goalStartDate = settings.goalStartDate
        record.goalStartIntroduced = settings.goalStartIntroduced
        record.goalStateRaw = settings.goalState?.rawValue
        record.examKindRaw = settings.examKind?.rawValue
        record.examDate = settings.examDate
        record.examDone = settings.examDone
        record.dailyConjugationCount = settings.dailyConjugationCount
        record.lastRecapWeek = settings.lastRecapWeek
        record.ccseDailyNewLimit = settings.ccseDailyNewLimit
        record.dailyNewWordCount = settings.dailyNewWordCount
        record.selectedDeckIDs = settings.selectedDeckIDs
        record.variantPromptAnswered = settings.variantPromptAnswered
        record.personalWordIDs = settings.personalWordIDs
        // Celebrated levels only grow: union of stored, incoming and mirrored values.
        let celebrated = CelebratedLevels.merge(CelebratedLevels.merge(record.celebratedLevels, settings.celebratedLevelsRaw),
                                                mirroredCelebrated)
        record.celebratedLevels = Self.nonEmpty(celebrated)
        // Write the mirror only on change (UserDefaults writes re-render @AppStorage views).
        if !celebrated.isEmpty, mirroredCelebrated != celebrated { localMirror?.set(celebrated, forKey: Self.celebratedMirrorKey) }
        try context.save()
    }

    // MARK: Reviews

    public func allReviews() throws -> [ReviewState] {
        try context.fetch(FetchDescriptor<ReviewRecord>()).map(Self.toDomain)
    }

    public func review(for cardID: String) throws -> ReviewState? {
        try fetchRecord(cardID: cardID).map(Self.toDomain)
    }

    public func upsertReview(_ review: ReviewState) throws {
        let record = try fetchRecord(cardID: review.cardID) ?? {
            let new = ReviewRecord(cardID: review.cardID)
            context.insert(new)
            return new
        }()
        record.easeFactor = review.easeFactor
        record.interval = review.interval
        record.repetitions = review.repetitions
        record.dueDate = review.dueDate
        record.lastGrade = review.lastGrade
        record.statusRaw = review.status.rawValue
        record.stability = review.stability
        record.difficulty = review.difficulty
        record.lastReviewDate = review.lastReviewDate
        record.schedulerVersion = review.schedulerVersion
        record.fsrsDueDate = review.fsrsDueDate
        try context.save()
    }

    // MARK: Events

    public func appendEvent(_ event: StudyEvent) throws {
        context.insert(EventRecord(eventID: event.id, cardID: event.cardID, date: event.date, grade: event.grade))
        try context.save()
    }

    public func allEvents() throws -> [StudyEvent] {
        try context.fetch(FetchDescriptor<EventRecord>()).map {
            StudyEvent(id: $0.eventID, cardID: $0.cardID, date: $0.date, grade: $0.grade)
        }
    }

    // MARK: Exercise attempts

    public func appendAttempt(_ attempt: ExerciseAttempt) throws {
        context.insert(AttemptRecord(
            attemptID: attempt.id,
            exerciseID: attempt.exerciseID,
            cardID: attempt.cardID,
            date: attempt.date,
            correct: attempt.correct,
            grade: attempt.grade,
            transcript: attempt.transcript
        ))
        try context.save()
    }

    public func allAttempts() throws -> [ExerciseAttempt] {
        try context.fetch(FetchDescriptor<AttemptRecord>()).map {
            ExerciseAttempt(
                id: $0.attemptID, exerciseID: $0.exerciseID, cardID: $0.cardID,
                date: $0.date, correct: $0.correct, grade: $0.grade, transcript: $0.transcript
            )
        }
    }

    // MARK: Trap practice (personal-traps)

    public func appendTrapPractice(_ event: TrapPracticeEvent) throws {
        context.insert(TrapPracticeRecord(eventID: event.id, cardID: event.cardID, date: event.date,
                                          outcomeRaw: event.outcome.rawValue))
        try context.save()
    }

    public func allTrapPractice() throws -> [TrapPracticeEvent] {
        try context.fetch(FetchDescriptor<TrapPracticeRecord>()).map {
            TrapPracticeEvent(id: $0.eventID, cardID: $0.cardID, date: $0.date,
                              outcome: TrapPracticeEvent.Outcome(rawValue: $0.outcomeRaw) ?? .stillConfused)
        }
    }

    // MARK: Mock attempts (exam-path-dele-ccse)

    public func upsertMockAttempt(_ a: MockAttempt) throws {
        let id = a.id
        var descriptor = FetchDescriptor<MockAttemptRecord>(predicate: #Predicate { $0.attemptID == id })
        descriptor.fetchLimit = 1
        let r = try context.fetch(descriptor).first ?? {
            let new = MockAttemptRecord(attemptID: a.id)
            context.insert(new)
            return new
        }()
        r.examID = a.examID
        r.form = a.form
        r.startedAt = a.startedAt
        r.sectionIndex = a.sectionIndex
        r.sectionStartedAt = a.sectionStartedAt
        r.answersJSON = Self.json(a.answers)
        r.rubricJSON = Self.json(a.rubricTicks)
        r.stateRaw = a.state.rawValue
        r.finishedAt = a.finishedAt
        r.sectionPointsJSON = Self.json(a.sectionPoints)
        r.expired = a.expired
        try context.save()
    }

    public func allMockAttempts() throws -> [MockAttempt] {
        try context.fetch(FetchDescriptor<MockAttemptRecord>()).map {
            MockAttempt(id: $0.attemptID, examID: $0.examID, form: $0.form, startedAt: $0.startedAt,
                        sectionIndex: $0.sectionIndex, sectionStartedAt: $0.sectionStartedAt,
                        answers: Self.decode($0.answersJSON) ?? [:], rubricTicks: Self.decode($0.rubricJSON) ?? [:],
                        state: MockAttempt.State(rawValue: $0.stateRaw) ?? .abandoned, finishedAt: $0.finishedAt,
                        sectionPoints: Self.decode($0.sectionPointsJSON) ?? [:], expired: $0.expired)
        }
    }

    public func deleteMockAttempt(_ id: UUID) throws {
        let records = try context.fetch(FetchDescriptor<MockAttemptRecord>(predicate: #Predicate { $0.attemptID == id }))
        records.forEach(context.delete)
        try context.save()
    }

    // MARK: Personal words (vocabulary-decks)

    public func savePersonalWord(_ w: PersonalWord) throws {
        let id = w.id
        let existing = try context.fetch(FetchDescriptor<PersonalWordRecord>(predicate: #Predicate { $0.wordID == id })).first
        let r = existing ?? {
            let new = PersonalWordRecord(wordID: w.id)
            context.insert(new)
            return new
        }()
        r.es = w.es
        r.ru = w.ru
        r.sourceCardID = w.sourceCardID
        r.createdAt = w.createdAt
        try context.save()
    }

    public func allPersonalWords() throws -> [PersonalWord] {
        try context.fetch(FetchDescriptor<PersonalWordRecord>()).map {
            PersonalWord(id: $0.wordID, es: $0.es, ru: $0.ru, sourceCardID: $0.sourceCardID, createdAt: $0.createdAt)
        }
    }

    public func deletePersonalWord(_ id: UUID) throws {
        try context.fetch(FetchDescriptor<PersonalWordRecord>(predicate: #Predicate { $0.wordID == id })).forEach(context.delete)
        try context.save()
    }

    public func requestItem(_ itemID: String, at date: Date) throws {
        let existing = try context.fetch(FetchDescriptor<RequestedItemRecord>(predicate: #Predicate { $0.itemID == itemID }))
        guard existing.isEmpty else { return }
        context.insert(RequestedItemRecord(itemID: itemID, requestedAt: date))
        try context.save()
    }

    /// One per item (the earliest, should sync ever duplicate a request).
    public func allRequestedItems() throws -> [RequestedItem] {
        var earliest: [String: Date] = [:]
        for r in try context.fetch(FetchDescriptor<RequestedItemRecord>()) {
            earliest[r.itemID] = min(earliest[r.itemID] ?? r.requestedAt, r.requestedAt)
        }
        return earliest.map { RequestedItem(itemID: $0.key, requestedAt: $0.value) }
            .sorted { $0.requestedAt != $1.requestedAt ? $0.requestedAt < $1.requestedAt : $0.itemID < $1.itemID }
    }

    public func deleteReview(for itemID: String) throws {
        if let r = try fetchRecord(cardID: itemID) { context.delete(r) }
        try context.save()
    }

    private static func json<T: Encodable>(_ value: T) -> String {
        (try? String(data: JSONEncoder().encode(value), encoding: .utf8)) ?? "{}"
    }

    private static func decode<T: Decodable>(_ s: String) -> T? {
        try? JSONDecoder().decode(T.self, from: Data(s.utf8))
    }

    // MARK: Helpers

    private static func nonEmpty(_ s: String) -> String? { s.isEmpty ? nil : s }

    private func fetchRecord(cardID: String) throws -> ReviewRecord? {
        let id = cardID
        var descriptor = FetchDescriptor<ReviewRecord>(predicate: #Predicate { $0.cardID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func toDomain(_ r: ReviewRecord) -> ReviewState {
        ReviewState(
            cardID: r.cardID,
            easeFactor: r.easeFactor,
            interval: r.interval,
            repetitions: r.repetitions,
            dueDate: r.dueDate,
            lastGrade: r.lastGrade,
            status: ReviewStatus(rawValue: r.statusRaw) ?? .new,
            stability: r.stability,
            difficulty: r.difficulty,
            lastReviewDate: r.lastReviewDate,
            schedulerVersion: r.schedulerVersion,
            fsrsDueDate: r.fsrsDueDate
        )
    }
}
