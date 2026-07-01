import Foundation
import SwiftData

/// Configuration for the user-data store.
public struct PersistenceConfig: Sendable {
    public var inMemory: Bool
    public var url: URL?
    /// When true, user data syncs through the user's private CloudKit database.
    /// Enabling this also requires the iCloud entitlement + container on the app
    /// target (see CLAUDE.md). Off by default so the app runs local-first.
    public var cloudKitEnabled: Bool
    public var cloudKitContainerID: String

    public init(
        inMemory: Bool = false,
        url: URL? = nil,
        cloudKitEnabled: Bool = false,
        cloudKitContainerID: String = "iCloud.com.toffguy.lorito"
    ) {
        self.inMemory = inMemory
        self.url = url
        self.cloudKitEnabled = cloudKitEnabled
        self.cloudKitContainerID = cloudKitContainerID
    }

    public static let `default` = PersistenceConfig()
}

public enum PersistenceController {
    public static let schema = Schema([
        SettingsRecord.self,
        ReviewRecord.self,
        EventRecord.self,
        AttemptRecord.self,
    ])

    public static func makeContainer(config: PersistenceConfig = .default) throws -> ModelContainer {
        let cloudKit: ModelConfiguration.CloudKitDatabase = config.cloudKitEnabled
            ? .private(config.cloudKitContainerID)
            : .none

        let modelConfig: ModelConfiguration
        if let url = config.url {
            modelConfig = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudKit)
        } else {
            modelConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: config.inMemory,
                cloudKitDatabase: cloudKit
            )
        }
        return try ModelContainer(for: schema, configurations: [modelConfig])
    }

    /// The container the app should use at runtime. `cloudKitEnabled` is decided
    /// by the app target (via a compile condition set only in builds that carry
    /// the iCloud entitlement) and passed in. When on, SwiftData mirrors to the
    /// private CloudKit DB and syncs whenever an iCloud account is available; it
    /// still works locally without one. We deliberately do NOT gate on
    /// `ubiquityIdentityToken`: that reflects iCloud *Drive*, not CloudKit, and is
    /// frequently nil on the Simulator even when signed into iCloud, which would
    /// wrongly drop the app to a local store and never create the CloudKit schema.
    public static func makeUserContainer(cloudKitEnabled: Bool) -> ModelContainer {
        if cloudKitEnabled {
            if let synced = try? makeContainer(config: PersistenceConfig(cloudKitEnabled: true)) {
                print("[Lorito] CloudKit sync ENABLED (private DB iCloud.com.toffguy.lorito)")
                return synced
            }
            print("[Lorito] CloudKit requested but container init failed — using local store")
        } else {
            print("[Lorito] CloudKit not enabled in this build — local store")
        }
        // Local-first fallback. Force-try: a local container failing is
        // unrecoverable and should crash loudly.
        return try! makeContainer(config: PersistenceConfig(cloudKitEnabled: false))
    }
}
