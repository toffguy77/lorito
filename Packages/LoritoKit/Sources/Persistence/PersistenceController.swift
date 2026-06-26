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

    /// The container the app should use at runtime. Enables private-database
    /// CloudKit sync when an iCloud account is available (and the entitlement is
    /// present, which makes the token non-nil); otherwise — or if the CloudKit
    /// container can't be opened — it falls back to a local store so the app is
    /// always usable. SwiftData mirrors the local store to CloudKit and converges
    /// once an account becomes available, so this is safe and lossless.
    public static func makeUserContainer() -> ModelContainer {
        let iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        if iCloudAvailable {
            if let synced = try? makeContainer(config: PersistenceConfig(cloudKitEnabled: true)) {
                return synced
            }
        }
        // Local-first fallback (no account / no entitlement / CloudKit unavailable).
        // Force-try: a local container failing is unrecoverable and should crash loudly.
        return try! makeContainer(config: PersistenceConfig(cloudKitEnabled: false))
    }
}
