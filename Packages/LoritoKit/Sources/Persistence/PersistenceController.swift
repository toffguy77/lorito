import Foundation
import SwiftData
import CoreData

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
    /// Every synced `@Model` type. New synced records are added here (and to
    /// `cloudkit/schema.ckdb` — see the synced-data checklist in CLAUDE.md).
    static let modelTypes: [any PersistentModel.Type] = [
        SettingsRecord.self,
        ReviewRecord.self,
        EventRecord.self,
        AttemptRecord.self,
        TrapPracticeRecord.self,
        MockAttemptRecord.self,
        PersonalWordRecord.self,
        RequestedItemRecord.self,
    ]

    public static let schema = Schema(modelTypes)

    public static func makeContainer(config: PersistenceConfig = .default) throws -> ModelContainer {
        let cloudKit: ModelConfiguration.CloudKitDatabase = config.cloudKitEnabled
            ? .private(config.cloudKitContainerID)
            : .none

        let modelConfig: ModelConfiguration
        if let url = config.url {
            modelConfig = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudKit)
        } else {
            // Keep the store in the app's own container. With the App Group
            // entitlement (widgets) the default would move it to the group
            // container, orphaning existing users' data on update.
            modelConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: config.inMemory,
                groupContainer: .none,
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
    /// `inMemory` (UI tests only): a fresh, unsynced store per launch.
    public static func makeUserContainer(cloudKitEnabled: Bool, inMemory: Bool = false) -> ModelContainer {
        if inMemory {
            return try! makeContainer(config: PersistenceConfig(inMemory: true, cloudKitEnabled: false))
        }
        if cloudKitEnabled {
            #if DEBUG
            if CommandLine.arguments.contains("-LoritoInitCloudKitSchema") { initializeCloudKitSchema() }
            #endif
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

    #if DEBUG
    /// Debug-only (`-LoritoInitCloudKitSchema`): create every record type and
    /// field of the current model in the CloudKit **development** environment,
    /// so `cktool export-schema` sees new synced fields. Runs before SwiftData
    /// opens the store, on the same file. Never compiled into Release builds.
    static func initializeCloudKitSchema(containerID: String = PersistenceConfig.default.cloudKitContainerID) {
        let url = ModelConfiguration(schema: schema, groupContainer: .none).url
        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: modelTypes) else {
            print("[Lorito] initializeCloudKitSchema: could not build the managed object model")
            return
        }
        let description = NSPersistentStoreDescription(url: url)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerID)
        description.shouldAddStoreAsynchronously = false
        let container = NSPersistentCloudKitContainer(name: "Lorito", managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { print("[Lorito] initializeCloudKitSchema: load failed: \(error)") }
        }
        do {
            try container.initializeCloudKitSchema()
            print("[Lorito] CloudKit development schema initialized")
        } catch {
            print("[Lorito] initializeCloudKitSchema failed: \(error)")
        }
        for store in container.persistentStoreCoordinator.persistentStores {
            try? container.persistentStoreCoordinator.remove(store)
        }
    }
    #endif
}
