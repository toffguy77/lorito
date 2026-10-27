import Foundation
import Testing
import Domain
@testable import Features

/// Collects delivered batches.
private actor RecordingSink: AnalyticsSink {
    var delivered: [AnalyticsRecord] = []
    func send(_ batch: [AnalyticsRecord]) async throws { delivered += batch }
}

private struct FailingSink: AnalyticsSink {
    struct Down: Error {}
    func send(_ batch: [AnalyticsRecord]) async throws { throw Down() }
}

@MainActor
private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "lorito.tests.analytics.\(UUID().uuidString)")!
}

@Suite("Analytics service")
@MainActor
struct AnalyticsServiceTests {
    @Test("Nothing is recorded before consent; first launch grants by default")
    func consentGate() {
        let defaults = freshDefaults()
        let service = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: defaults, queueURL: nil)
        service.record(.reminderOpened)
        #expect(service.queue.records.isEmpty)
        service.resolveConsentOnFirstLaunch()
        #expect(defaults.string(forKey: AnalyticsConsent.key) == "granted")
        service.record(.reminderOpened)
        #expect(service.queue.records.count == 1)
    }

    @Test("Opt-out purges the queue and stops recording")
    func optOut() {
        let service = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: freshDefaults(), queueURL: nil)
        service.resolveConsentOnFirstLaunch()
        service.record(.onboardingCompleted)
        service.setEnabled(false)
        #expect(service.queue.records.isEmpty)
        service.record(.reminderOpened)
        #expect(service.queue.records.isEmpty)
    }

    @Test("Flush delivers in batches and empties the queue")
    func flush() async {
        let sink = RecordingSink()
        let service = AnalyticsService(sink: sink, defaults: freshDefaults(), queueURL: nil)
        service.resolveConsentOnFirstLaunch()
        for i in 0..<120 { service.record(.streakExtended(length: i)) }
        await service.flush()
        #expect(service.queue.records.isEmpty)
        #expect(await sink.delivered.count == 120)
    }

    @Test("A failing sink keeps events queued and backs off")
    func failing() async {
        var clock = Date(timeIntervalSince1970: 1_800_000_000)
        let service = AnalyticsService(sink: FailingSink(), defaults: freshDefaults(), queueURL: nil, now: { clock })
        service.resolveConsentOnFirstLaunch()
        service.record(.reminderOpened)
        await service.flush()
        #expect(service.queue.records.count == 1)
        clock = clock.addingTimeInterval(10)
        await service.flush()                     // still backing off: no attempt, nothing lost
        #expect(service.queue.records.count == 1)
    }

    @Test("Queue survives a relaunch from its file")
    func persistence() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("aq-\(UUID().uuidString).json")
        let defaults = freshDefaults()
        let service = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: defaults, queueURL: url, flushEnabled: false)
        service.resolveConsentOnFirstLaunch()
        service.record(.onboardingCompleted)
        try await Task.sleep(nanoseconds: 300_000_000)    // off-main write
        let relaunched = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: defaults, queueURL: url)
        #expect(relaunched.queue.records.map(\.name) == ["onboardingCompleted"])
    }

    @Test("Streak: extension when it grows, loss once on launch after a break")
    func streak() {
        let service = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: freshDefaults(), queueURL: nil)
        service.resolveConsentOnFirstLaunch()
        service.noteStreak(1); service.noteStreak(1); service.noteStreak(2)
        service.checkStreakOnLaunch(0); service.checkStreakOnLaunch(0)
        #expect(service.queue.records.map(\.event) == [.streakExtended(length: 1), .streakExtended(length: 2), .streakLost(previous: 2)])
    }

    @Test("Consent is per device: a separate defaults suite has its own value")
    func perDevice() {
        let iphone = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: freshDefaults(), queueURL: nil)
        iphone.resolveConsentOnFirstLaunch(); iphone.setEnabled(false)
        let ipad = AnalyticsService(sink: NoOpAnalyticsSink(), defaults: freshDefaults(), queueURL: nil)
        ipad.resolveConsentOnFirstLaunch()
        #expect(!iphone.isEnabled && ipad.isEnabled)
    }
}

@MainActor
private final class Recorder: AnalyticsRecording {
    var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) { events.append(event) }
}

private final class NullStore: UserDataStore {
    var reviews: [String: ReviewState] = [:]
    var events: [StudyEvent] = []
    func loadSettings() throws -> UserSettings { .default }
    func saveSettings(_ s: UserSettings) throws {}
    func allReviews() throws -> [ReviewState] { Array(reviews.values) }
    func review(for cardID: String) throws -> ReviewState? { reviews[cardID] }
    func upsertReview(_ r: ReviewState) throws { reviews[r.cardID] = r }
    func appendEvent(_ e: StudyEvent) throws { events.append(e) }
    func allEvents() throws -> [StudyEvent] { events }
}

@Suite("Analytics emit points")
@MainActor
struct AnalyticsEmitPointTests {
    static let catalog = ContentCatalog(themes: [Theme(id: "a1-1", level: .a1, title: "T", order: 1)], cards: [
        Card(id: "A1-01", level: .a1, themeID: "a1-1", order: 1, title: "A", body: ""),
        Card(id: "A1-02", level: .a1, themeID: "a1-1", order: 2, title: "B", body: ""),
    ])

    @Test("Study session: grade events carry kind only; completion carries item count")
    func session() {
        let recorder = Recorder()
        let s = StudySessionModel(store: NullStore(), catalog: Self.catalog, queue: ["A1-01", "A1-02"], analytics: recorder)
        s.reveal(); s.grade(.good)
        s.reveal(); s.grade(.easy)
        #expect(recorder.events == [
            .itemGraded(kind: .card, grade: .good, revealed: true),
            .itemGraded(kind: .card, grade: .easy, revealed: true),
            .sessionCompleted(items: 2, firstTryPercent: 100),
        ])
    }

    @Test("Exercise answered carries type and correctness")
    func exercise() {
        let recorder = Recorder()
        let ex = Exercise(id: "A1-EX-01", level: .a1, themeID: "a1-1", card: "A1-01", prompt: "?", explanation: "",
                          kind: .multipleChoice(options: ["el", "la"], answer: "el"))
        let m = ExerciseSessionModel(store: NullStore(), exercises: [ex], analytics: recorder)
        m.selectedOption = "la"
        m.submit()
        #expect(recorder.events == [.exerciseAnswered(type: .multipleChoice, correct: false)])
    }
}
