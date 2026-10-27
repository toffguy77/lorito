import Foundation
import CloudKit
import Domain

/// The pair as seen from this device.
public enum BuddyRole: Sendable, Equatable {
    case none
    /// Created the share; `hasPartner` once someone accepted it.
    case owner(hasPartner: Bool)
    case participant
}

/// Remote storage for study buddy (CloudKit share in production, a fake in tests).
@MainActor
public protocol BuddyBackend: AnyObject {
    /// iCloud account available (sync on is checked by the caller).
    func isAvailable() async -> Bool
    /// This user's CloudKit user record name.
    func currentUser() async throws -> String
    func role() async throws -> BuddyRole
    /// This user's name as the share shows it (shown to the partner).
    func displayName() async -> String
    /// The owner's share, created on first use (never a second invite).
    func prepareShare() async throws -> BuddyInvite
    /// Upserts this user's days and prunes their records older than 14 days.
    func publish(_ days: [BuddyDay], owner: String) async throws
    func fetch() async throws -> (days: [BuddyDay], nudges: [BuddyNudge])
    func send(_ nudge: BuddyNudge) async throws
    /// Nudge notifications (owner: private DB; participant: shared DB).
    func registerNudgeSubscription() async throws
    /// Owner deletes the share and zone; the participant leaves the share.
    func leave() async throws
}

/// What `UICloudSharingController` needs (nil share in tests).
public struct BuddyInvite: @unchecked Sendable {
    public let share: CKShare?
    public let container: CKContainer?

    public init(share: CKShare?, container: CKContainer?) {
        self.share = share
        self.container = container
    }
}

/// CloudKit implementation: one owner zone `BuddyZone` with a zone-wide share
/// (participant permission read-write); both partners write their own
/// `BuddyDay` and `BuddyNudge` records into it.
@MainActor
public final class CloudKitBuddyBackend: BuddyBackend {
    static let zoneName = "BuddyZone"
    static let subscriptionID = "buddy-nudges"
    static let nudgeAlert = "Ваш напарник напоминает: пора повторить испанский"

    private let container: CKContainer
    private var privateDB: CKDatabase { container.privateCloudDatabase }
    private var sharedDB: CKDatabase { container.sharedCloudDatabase }
    private var ownZoneID: CKRecordZone.ID { CKRecordZone.ID(zoneName: Self.zoneName) }

    public init(containerID: String = "iCloud.com.toffguy.lorito") {
        container = CKContainer(identifier: containerID)
    }

    public func isAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    public func currentUser() async throws -> String {
        try await container.userRecordID().recordName
    }

    /// The zone holding the pair: own (owner) or the accepted one (participant).
    private func pairZone() async throws -> (CKDatabase, CKRecordZone.ID)? {
        if let shared = try await sharedDB.allRecordZones().first(where: { $0.zoneID.zoneName == Self.zoneName }) {
            return (sharedDB, shared.zoneID)
        }
        if try await privateDB.allRecordZones().contains(where: { $0.zoneID == ownZoneID }) {
            return (privateDB, ownZoneID)
        }
        return nil
    }

    private func ownShare() async throws -> CKShare? {
        let id = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: ownZoneID)
        return try? await privateDB.record(for: id) as? CKShare
    }

    public func role() async throws -> BuddyRole {
        guard let (db, _) = try await pairZone() else { return .none }
        if db === sharedDB { return .participant }
        let share = try await ownShare()
        let accepted = share?.participants.contains { $0.role != .owner && $0.acceptanceStatus == .accepted } ?? false
        return .owner(hasPartner: accepted)
    }

    public func displayName() async -> String {
        let share: CKShare?
        if let (db, zone) = try? await pairZone(), db === sharedDB {
            let id = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone)
            share = try? await sharedDB.record(for: id) as? CKShare
        } else {
            share = try? await ownShare()
        }
        let name = share?.currentUserParticipant?.userIdentity.nameComponents
            .map { PersonNameComponentsFormatter.localizedString(from: $0, style: .short) } ?? ""
        return name.isEmpty ? "Напарник" : name
    }

    public func prepareShare() async throws -> BuddyInvite {
        if let share = try await ownShare() { return BuddyInvite(share: share, container: container) }
        _ = try await privateDB.save(CKRecordZone(zoneID: ownZoneID))
        let share = CKShare(recordZoneID: ownZoneID)
        share[CKShare.SystemFieldKey.title] = "Учим испанский вместе — Lorito"
        share.publicPermission = .none
        let saved = try await privateDB.save(share) as? CKShare ?? share
        return BuddyInvite(share: saved, container: container)
    }

    public func publish(_ days: [BuddyDay], owner: String) async throws {
        guard let (db, zone) = try await pairZone() else { return }
        let records: [CKRecord] = days.map { d in
            let r = CKRecord(recordType: "BuddyDay", recordID: CKRecord.ID(recordName: d.recordName, zoneID: zone))
            r["owner"] = d.owner
            r["day"] = d.day
            r["studied"] = d.studied ? 1 : 0
            r["gradedCount"] = d.gradedCount
            r["currentStreak"] = d.currentStreak
            r["displayName"] = d.displayName
            return r
        }
        let keep = Set(days.map(\.recordName))
        let (existing, _) = try await fetchRecords(db, zone)
        let stale = existing.filter { $0.recordType == "BuddyDay" && ($0["owner"] as? String) == owner
            && !keep.contains($0.recordID.recordName) }.map(\.recordID)
        _ = try await db.modifyRecords(saving: records, deleting: stale, savePolicy: .changedKeys)
    }

    public func fetch() async throws -> (days: [BuddyDay], nudges: [BuddyNudge]) {
        guard let (db, zone) = try await pairZone() else { return ([], []) }
        let (records, _) = try await fetchRecords(db, zone)
        let days = records.filter { $0.recordType == "BuddyDay" }.compactMap { r -> BuddyDay? in
            guard let owner = r["owner"] as? String, let day = r["day"] as? String else { return nil }
            return BuddyDay(owner: owner, day: day, studied: (r["studied"] as? Int ?? 0) != 0,
                            gradedCount: r["gradedCount"] as? Int ?? 0, currentStreak: r["currentStreak"] as? Int ?? 0,
                            displayName: r["displayName"] as? String ?? "")
        }
        let nudges = records.filter { $0.recordType == "BuddyNudge" }.compactMap { r -> BuddyNudge? in
            guard let from = r["from"] as? String, let day = r["day"] as? String else { return nil }
            return BuddyNudge(from: from, day: day)
        }
        return (days, nudges)
    }

    /// Every record of the zone (no query index needed).
    private func fetchRecords(_ db: CKDatabase, _ zone: CKRecordZone.ID) async throws -> ([CKRecord], CKServerChangeToken?) {
        var out: [CKRecord] = []
        var token: CKServerChangeToken?
        var more = true
        while more {
            let changes = try await db.recordZoneChanges(inZoneWith: zone, since: token)
            out += changes.modificationResultsByID.values.compactMap { try? $0.get().record }
            token = changes.changeToken
            more = changes.moreComing
        }
        return (out, token)
    }

    public func send(_ nudge: BuddyNudge) async throws {
        guard let (db, zone) = try await pairZone() else { return }
        let r = CKRecord(recordType: "BuddyNudge", recordID: CKRecord.ID(recordName: nudge.recordName, zoneID: zone))
        r["from"] = nudge.from
        r["day"] = nudge.day
        _ = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
    }

    public func registerNudgeSubscription() async throws {
        guard let (db, _) = try await pairZone() else { return }
        let sub = CKDatabaseSubscription(subscriptionID: Self.subscriptionID)
        sub.recordType = "BuddyNudge"
        let info = CKSubscription.NotificationInfo()
        info.alertBody = Self.nudgeAlert
        info.soundName = "default"
        sub.notificationInfo = info
        _ = try await db.save(sub)
    }

    public func leave() async throws {
        guard let (db, zone) = try await pairZone() else { return }
        try? await db.deleteSubscription(withID: Self.subscriptionID)
        _ = try await db.deleteRecordZone(withID: zone)
    }

    /// Accept an invite (scene delegate `userDidAcceptCloudKitShareWith`).
    public static func accept(_ metadata: CKShare.Metadata) async throws {
        _ = try await CKContainer(identifier: metadata.containerIdentifier).accept(metadata)
    }
}
