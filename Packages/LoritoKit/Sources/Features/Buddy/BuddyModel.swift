import Foundation
import Observation
import Domain

/// Study buddy: invite one partner, share daily aggregates, a shared streak and
/// a once-a-day nudge. Only aggregates leave the device.
@MainActor
@Observable
public final class BuddyModel {
    public struct Pair: Equatable, Sendable {
        public let partnerName: String
        public let partnerStreak: Int
        public let partnerStudiedToday: Bool
        /// Partner's last seven days, oldest first.
        public let week: [BuddyDay]
        public let sharedStreak: Int
        public let canNudge: Bool
        public let nudgedByPartnerToday: Bool
    }

    public enum State: Equatable, Sendable {
        case loading
        /// No iCloud account or sync off: explanation, no invite.
        case unavailable
        case invite
        case waitingForPartner
        case paired(Pair)
    }

    /// Posted by the app after accepting a buddy invite.
    public nonisolated static let shareAccepted = Notification.Name("lorito.buddy.shareAccepted")

    public private(set) var state: State = .loading
    public private(set) var isWorking = false

    private let backend: BuddyBackend?
    private let store: UserDataStore
    private let syncEnabled: Bool
    private let analytics: AnalyticsRecording
    private let now: () -> Date
    private var me: String?

    public init(backend: BuddyBackend?, store: UserDataStore, syncEnabled: Bool, analytics: AnalyticsRecording? = nil,
                now: @escaping () -> Date = { Date() }) {
        self.backend = backend
        self.store = store
        self.syncEnabled = syncEnabled
        self.analytics = analytics ?? AnalyticsService.shared
        self.now = now
    }

    /// Foreground, session end and day rollover: publish today, fetch the partner.
    public func refresh() async {
        guard let backend, syncEnabled, await backend.isAvailable(), let me = try? await backend.currentUser() else {
            state = .unavailable
            return
        }
        self.me = me
        let role = (try? await backend.role()) ?? BuddyRole.none
        switch role {
        case .none:
            state = .invite
        case .owner(hasPartner: false):
            state = .waitingForPartner
        case .owner(hasPartner: true), .participant:
            let name = await backend.displayName()
            let mine = BuddyAggregate.days(events: (try? store.allEvents()) ?? [], today: now(), owner: me, displayName: name)
            try? await backend.publish(mine, owner: me)
            try? await backend.registerNudgeSubscription()
            let (days, nudges) = (try? await backend.fetch()) ?? ([], [])
            state = .paired(pair(me: me, mine: mine, all: days, nudges: nudges))
        }
    }

    private func pair(me: String, mine: [BuddyDay], all: [BuddyDay], nudges: [BuddyNudge]) -> Pair {
        let theirs = all.filter { $0.owner != me }
        let today = now()
        let key = BuddyDayKey.key(today)
        let latest = theirs.max { $0.day < $1.day }
        return Pair(partnerName: latest?.displayName ?? "Напарник",
                    partnerStreak: latest?.currentStreak ?? 0,
                    partnerStudiedToday: theirs.contains { $0.day == key && $0.studied },
                    week: BuddyAggregate.lastSeven(theirs, today: today),
                    sharedStreak: SharedStreakCalculator.streak(mine: mine, theirs: theirs, today: today),
                    canNudge: NudgeRule.canNudge(from: me, sent: nudges, partnerDays: theirs, today: today),
                    nudgedByPartnerToday: nudges.contains { $0.from != me && $0.day == key })
    }

    /// The share for `UICloudSharingController` (created once); nil when unavailable.
    public func invite() async -> BuddyInvite? {
        guard let backend, state != .unavailable, syncEnabled else { return nil }
        let first = state == .invite
        guard let invite = try? await backend.prepareShare() else { return nil }
        if first { analytics.record(.buddyInviteSent) }
        state = .waitingForPartner
        return invite
    }

    public func nudge() async {
        guard let backend, let me, case .paired(let p) = state, p.canNudge, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await backend.send(BuddyNudge(from: me, day: BuddyDayKey.key(now())))
            analytics.record(.buddyNudgeSent)
        } catch { return }
        await refresh()
    }

    /// «Перестать учиться вместе».
    public func leave() async {
        guard let backend else { return }
        try? await backend.leave()
        analytics.record(.buddyLeft)
        await refresh()
    }
}
