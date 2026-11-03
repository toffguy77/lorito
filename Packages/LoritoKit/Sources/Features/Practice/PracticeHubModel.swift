import Foundation
import Observation
import Domain

/// Free practice outside a card's reader (practice-hub): availability counts per
/// mode and starting a session, an explained empty state or the paywall.
@MainActor
@Observable
public final class PracticeHubModel {
    /// What choosing a mode leads to.
    public enum Start {
        case session(ExerciseSessionModel)
        case empty(String)
        case paywall
    }

    static let nothingStudied = "Упражнения открываются, когда вы изучаете карточки. Начните с плана на сегодня."
    static let noMisses = "Ошибок пока нет — слабые места появятся здесь, когда они будут."
    static let audioOnly = "Доступные упражнения здесь — на слух или произношение, а они сейчас выключены или недоступны."

    let store: UserDataStore
    let catalog: ContentCatalog
    private let salesEnabled: Bool
    private let analytics: AnalyticsRecording
    private let preferences: AudioExercisePreferences
    private let seed: () -> UInt64
    private var reviews: [String: ReviewState] = [:]
    private var attempts: [ExerciseAttempt] = []

    public init(store: UserDataStore, catalog: ContentCatalog, salesEnabled: Bool = Monetization.salesEnabled,
                analytics: AnalyticsRecording? = nil, preferences: AudioExercisePreferences = .shared,
                seed: @escaping () -> UInt64 = { UInt64.random(in: .min ... .max) }) {
        self.store = store
        self.catalog = catalog
        self.salesEnabled = salesEnabled
        self.analytics = analytics ?? AnalyticsService.shared
        self.preferences = preferences
        self.seed = seed
        refresh()
    }

    public func refresh() {
        reviews = Dictionary(((try? store.allReviews()) ?? []).map { ($0.cardID, $0) }, uniquingKeysWith: { a, _ in a })
        attempts = (try? store.allAttempts()) ?? []
    }

    public func availability(_ mode: PracticeMode) -> PracticeAvailability {
        PracticeSelector.availability(mode, catalog: catalog, reviews: reviews, attempts: attempts)
    }

    /// Free practice is Pro; everyone has it while sales are off.
    public func isUnlocked(_ purchases: PurchaseService?) -> Bool {
        !salesEnabled || (purchases?.isEntitled(.practice) ?? false)
    }

    public func start(_ mode: PracticeMode, purchases: PurchaseService?, hasSpanishVoice: Bool) -> Start {
        guard isUnlocked(purchases) else { return .paywall }
        refresh()
        let exercises = PracticeSelector.select(mode, catalog: catalog, reviews: reviews, attempts: attempts, seed: seed())
        guard !exercises.isEmpty else {
            if case .weakSpots = mode, availability(.mixed).available > 0 { return .empty(Self.noMisses) }
            return .empty(Self.nothingStudied)
        }
        let variant = (try? store.loadSettings())?.spanishVariant ?? .spain
        let session = ExerciseSessionModel(store: store, exercises: exercises, analytics: analytics,
                                           recognizer: SystemSpeechRecognizer(variant: variant),
                                           hasSpanishVoice: hasSpanishVoice, preferences: preferences, grading: .free)
        guard session.count > 0 else { return .empty(Self.audioOnly) }
        analytics.record(.practiceStarted(mode: mode.name, count: session.count))
        return .session(session)
    }
}
