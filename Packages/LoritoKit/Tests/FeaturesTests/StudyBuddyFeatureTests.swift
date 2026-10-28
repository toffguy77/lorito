import Foundation
import Testing
import Domain
import Persistence
@testable import Features

@MainActor
private func freshStore() throws -> SwiftDataUserDataStore {
    SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)))
}

/// In-memory stand-in for the CloudKit share (both partners write into `records`).
@MainActor
final class FakeBuddyBackend: BuddyBackend {
    var available = true
    var me = "me"
    var currentRole: BuddyRole = .none
    var days: [BuddyDay] = []
    var nudges: [BuddyNudge] = []
    var subscribed = false
    var invites = 0
    var sendFails = false

    func isAvailable() async -> Bool { available }
    func currentUser() async throws -> String { me }
    func role() async throws -> BuddyRole { currentRole }
    func displayName() async -> String { "Аня" }
    func prepareShare() async throws -> BuddyInvite {
        if currentRole == .none { currentRole = .owner(hasPartner: false); invites += 1 }
        return BuddyInvite(share: nil, container: nil)
    }
    func publish(_ mine: [BuddyDay], owner: String) async throws {
        days.removeAll { $0.owner == owner }
        days += mine
    }
    func fetch() async throws -> (days: [BuddyDay], nudges: [BuddyNudge]) { (days, nudges) }
    func send(_ nudge: BuddyNudge) async throws {
        if sendFails { throw NSError(domain: "CKErrorDomain", code: 3, userInfo: ["partner": "Борис"]) }
        nudges.append(nudge)
    }
    func registerNudgeSubscription() async throws { subscribed = true }
    func leave() async throws { currentRole = .none; days.removeAll(); nudges.removeAll() }
}

final class BuddyRecorder: AnalyticsRecording {
    var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) { events.append(event) }
}

@Suite("Study buddy model")
@MainActor
struct StudyBuddyFeatureTests {
    let cal = Calendar.learningDay
    let now = Date()
    var todayKey: String { BuddyDayKey.key(now) }
    func partnerDay(_ offset: Int, studied: Bool = true, streak: Int = 3) -> BuddyDay {
        BuddyDay(owner: "you", day: BuddyDayKey.key(cal.date(byAdding: .day, value: -offset, to: now)!), studied: studied,
                 gradedCount: studied ? 7 : 0, currentStreak: streak, displayName: "Борис")
    }

    func model(_ backend: FakeBuddyBackend?, syncEnabled: Bool = true, recorder: BuddyRecorder = BuddyRecorder(),
               store: UserDataStore? = nil) throws -> BuddyModel {
        BuddyModel(backend: backend, store: try store ?? freshStore(), syncEnabled: syncEnabled, analytics: recorder,
                   now: { now })
    }

    @Test("Without iCloud or with sync off: an explanation, no invite")
    func unavailable() async throws {
        let backend = FakeBuddyBackend()
        backend.available = false
        let m = try model(backend)
        await m.refresh()
        #expect(m.state == .unavailable)
        #expect(await m.invite() == nil && backend.invites == 0)
        let off = try model(FakeBuddyBackend(), syncEnabled: false)
        await off.refresh()
        #expect(off.state == .unavailable)
        let none = try model(nil)
        await none.refresh()
        #expect(none.state == .unavailable)
    }

    @Test("Invite once; waiting until the partner accepts; then paired with aggregates only")
    func inviteAndPair() async throws {
        let backend = FakeBuddyBackend()
        let recorder = BuddyRecorder()
        let store = try freshStore()
        try store.appendEvent(StudyEvent(cardID: "A1-01", date: now, grade: "good"))
        let m = try model(backend, recorder: recorder, store: store)
        await m.refresh()
        #expect(m.state == .invite)
        _ = await m.invite()
        _ = await m.invite()
        #expect(backend.invites == 1)
        #expect(recorder.events.filter { $0 == .buddyInviteSent }.count == 1)
        await m.refresh()
        #expect(m.state == .waitingForPartner)

        backend.currentRole = .owner(hasPartner: true)
        backend.days += [partnerDay(0), partnerDay(1), partnerDay(2)]
        await m.refresh()
        guard case .paired(let pair) = m.state else { Issue.record("not paired: \(m.state)"); return }
        #expect(pair.partnerName == "Борис" && pair.partnerStreak == 3 && pair.partnerStudiedToday)
        #expect(pair.week.count == 7 && pair.week.last?.studied == true)
        #expect(pair.sharedStreak == 1)                       // I studied today only
        #expect(backend.days.contains { $0.owner == "me" && $0.day == todayKey && $0.studied && $0.gradedCount == 1 })
        #expect(backend.days.filter { $0.owner == "me" }.count == BuddyAggregate.publishedDays)
        #expect(backend.subscribed)
    }

    @Test("Nudge: sent once a day; disabled after sending and when the partner studied today")
    func nudge() async throws {
        let backend = FakeBuddyBackend()
        backend.currentRole = .participant
        backend.days = [partnerDay(0, studied: false)]
        let recorder = BuddyRecorder()
        let m = try model(backend, recorder: recorder)
        await m.refresh()
        guard case .paired(let before) = m.state else { Issue.record("not paired"); return }
        #expect(before.canNudge)
        await m.nudge()
        #expect(backend.nudges == [BuddyNudge(from: "me", day: todayKey)])
        #expect(recorder.events.last == .buddyNudgeSent)
        guard case .paired(let after) = m.state else { Issue.record("not paired"); return }
        #expect(!after.canNudge)
        await m.nudge()
        #expect(backend.nudges.count == 1)

        backend.nudges = []
        backend.days = [partnerDay(0, studied: true)]
        await m.refresh()
        guard case .paired(let studied) = m.state else { Issue.record("not paired"); return }
        #expect(!studied.canNudge)
    }

    @Test("A failed nudge is reported (area buddy, domain and code) and not recorded as sent")
    func nudgeFailure() async throws {
        final class Reports: ErrorReporting, @unchecked Sendable {
            let lock = NSLock()
            var items: [ErrorReport] = []
            func report(_ report: ErrorReport) { lock.withLock { items.append(report) } }
        }
        let backend = FakeBuddyBackend()
        backend.currentRole = .participant
        backend.days = [partnerDay(0, studied: false)]
        backend.sendFails = true
        let recorder = BuddyRecorder()
        let m = try model(backend, recorder: recorder)
        await m.refresh()
        let reports = Reports()
        await ErrorReports.$override.withValue(reports) { await m.nudge() }
        #expect(reports.items == [ErrorReport(area: .buddy, domain: "CKErrorDomain", code: 3)])
        #expect(!recorder.events.contains(.buddyNudgeSent))
    }

    @Test("Own nudges never count as received; leaving returns to the invite state")
    func leave() async throws {
        let backend = FakeBuddyBackend()
        backend.currentRole = .participant
        backend.days = [partnerDay(0, studied: false)]
        backend.nudges = [BuddyNudge(from: "you", day: todayKey)]
        let recorder = BuddyRecorder()
        let m = try model(backend, recorder: recorder)
        await m.refresh()
        guard case .paired(let pair) = m.state else { Issue.record("not paired"); return }
        #expect(pair.canNudge && pair.nudgedByPartnerToday)
        await m.leave()
        #expect(m.state == .invite)
        #expect(recorder.events.last == .buddyLeft)
    }
}

import CloudKit

@Suite("Study buddy: record attribution")
struct BuddyAttributionTests {
    @Test("Own records (default owner) map to me; others keep the server-set creator; none without creator")
    func creator() {
        let mine = CKRecord(recordType: "BuddyDay")
        #expect(CloudKitBuddyBackend.user(mine.creatorUserRecordID, me: "me") == nil)   // unsaved: no creator
        #expect(CloudKitBuddyBackend.user(CKRecord.ID(recordName: CKCurrentUserDefaultName), me: "me") == "me")
        #expect(CloudKitBuddyBackend.user(CKRecord.ID(recordName: "_abc"), me: "me") == "_abc")
        #expect(!CloudKitBuddyBackend.isAuthored(mine, by: "me", me: "me"))
    }
}
