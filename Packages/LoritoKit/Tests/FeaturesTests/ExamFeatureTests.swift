import Foundation
import Testing
import Domain
import Content
import Persistence
@testable import Features

private final class ProFake: ProStore, @unchecked Sendable {
    let entitled: Bool
    init(_ entitled: Bool) { self.entitled = entitled }
    func products() async throws -> [ProProductInfo] { [] }
    func currentPurchases() async -> [VerifiedPurchase] {
        entitled ? [VerifiedPurchase(productID: ProProducts.lifetime, expirationDate: nil, revocationDate: nil,
                                     ownership: .purchased, inGracePeriod: false)] : []
    }
    func purchase(_ productID: String) async throws -> PurchaseOutcome { .cancelled }
    func sync() async throws {}
    func listenForUpdates(_ onUpdate: @escaping @Sendable () async -> Void) -> Task<Void, Never> { Task {} }
}

private final class Silent: AnalyticsRecording { func record(_ event: AnalyticsEvent) {} }

@Suite("Exam path")
@MainActor
struct ExamFeatureTests {
    func setup(pro: Bool, now: @escaping () -> Date = { Date() }) async throws -> (ExamsModel, SwiftDataUserDataStore) {
        let store = SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
        let purchases = PurchaseService(store: ProFake(pro), defaults: UserDefaults(suiteName: UUID().uuidString)!, analytics: Silent())
        await purchases.refresh()
        return (ExamsModel(store: store, catalog: try ContentLoader.loadCatalog(), purchases: purchases, analytics: Silent(), now: now), store)
    }

    @Test("Non-Pro: preview form runs the preview items only; a second form shows the paywall and creates no attempt")
    func gating() async throws {
        let (m, store) = try await setup(pro: false)
        #expect(m.start("dele-a2", form: 2) == nil)
        #expect(try store.allMockAttempts().isEmpty)
        let runner = try #require(m.start("dele-a2", form: 1))
        #expect(runner.items.allSatisfy(\.preview) && runner.section?.id == "reading")
        #expect(try store.allMockAttempts().count == 1)
    }

    @Test("Pro: full mock; finishing every section completes and scores it")
    func pro() async throws {
        let (m, _) = try await setup(pro: true)
        let r = try #require(m.start("dele-a2", form: 2))
        #expect(r.items.count == 19)
        for item in r.sectionItems { if let a = item.correctAnswer { r.answer(item, a) } }
        for _ in 0..<4 { r.submitSection() }
        #expect(r.isFinished && r.result != nil)
        #expect(r.result?.failingGroups.contains("g2") == true)       // listening unanswered, speaking not self-assessed
    }

    @Test("Closing the app past the section limit: the attempt is closed on next load")
    func expiry() async throws {
        var clock = Date()
        let (m, store) = try await setup(pro: true, now: { clock })
        _ = try #require(m.start("dele-a2", form: 3))
        clock = clock.addingTimeInterval(61 * 60)
        m.refresh()
        let a = try #require(try store.allMockAttempts().first)
        #expect(a.state == .completed && a.expired)
    }

    @Test("Countdown from the study goal's exam date")
    func countdown() async throws {
        let (m, store) = try await setup(pro: false)
        var s = try store.loadSettings()
        s.exam = ExamGoal(kind: .deleA2, date: Calendar.learningDay.date(byAdding: .day, value: 39, to: Date())!)
        try store.saveSettings(s)
        #expect(m.countdown("dele-a2") == 40)
        #expect(m.countdown("ccse") == nil)
    }
}
