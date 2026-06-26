## Why

Lorito v1 ships local-first: progress (reviews, settings, study log) lives only on the device that created it. A learner who reinstalls the app, gets a new phone, or studies across an iPhone and (future) iPad loses their spaced-repetition history. The `bootstrap-foundation` work deliberately prepared for sync but left it off — the SwiftData `@Model` records are already CloudKit-safe (all properties defaulted, no unique constraints), `PersistenceConfig.cloudKitEnabled` exists behind a flag, and `Lorito.entitlements` is written but not wired into the target. This change turns that latent capability on: per-user progress syncs through the user's **private** CloudKit database, with no custom backend.

## What Changes

- **Wire the iCloud/CloudKit capability into the build**: add `Lorito.entitlements` to the app target in `project.yml` (`CODE_SIGN_ENTITLEMENTS`), register the iCloud capability + container `iCloud.com.toffguy.lorito` on the App ID, and ensure the App Store provisioning profile includes it.
- **Enable sync at runtime**: drive `PersistenceConfig.cloudKitEnabled` from a build/runtime decision (on for Release with entitlements present) so `PersistenceController` builds the `ModelContainer` with `.private` CloudKit database.
- **Define sync behavior**: progress written on one device appears on another signed into the same Apple ID; the store merges remote changes into the running app; first launch on a new device hydrates from CloudKit before composing the daily plan.
- **Define the no-account / unavailable case**: when the user is not signed into iCloud or CloudKit is unavailable, the app continues to work entirely locally and converges once an account becomes available — no data loss, no blocking UI.
- **Handle merge semantics**: concurrent edits to the same `CardReview`/settings resolve deterministically (last-writer-wins per record is acceptable for this data) without duplicating cards or losing the study log.
- **Migration**: existing local-only data from a v1 install is uploaded to CloudKit on first run with sync enabled (no reset).

This change introduces no new screens and no third-party dependencies. It activates and specifies the sync that the foundation prepared.

## Capabilities

### New Capabilities
- `cloudkit-sync`: Per-user progress synchronization through the user's private CloudKit database — wiring the iCloud capability/entitlement and container into the build, enabling the CloudKit-backed `ModelContainer`, multi-device convergence of `CardReview`/`UserSettings`/`StudyLog`, the local-only fallback when no iCloud account is available, deterministic merge of concurrent edits, and migration of existing local data on first sync.

### Modified Capabilities
<!-- None at the requirement level. This builds on app-foundation's CloudKit-ready persistence model and `PersistenceConfig.cloudKitEnabled` flag without redefining the foundation's storage contract; it specifies the new sync behavior as its own capability. -->

## Impact

- **Code**: `project.yml` (entitlements + `CODE_SIGN_ENTITLEMENTS` on the Lorito target); `PersistenceController`/`PersistenceConfig` (resolve `cloudKitEnabled`, build the container with `.private(containerID)`); app startup to surface account state and trigger initial sync; no changes to the pure `Domain` layer.
- **App Store / signing**: the App ID needs the iCloud capability + the `iCloud.com.toffguy.lorito` container; the distribution provisioning profile must carry the iCloud entitlement (handled via the existing fastlane signing path).
- **Foundation contracts consumed (not modified)**: the CloudKit-safe `SettingsRecord`/`ReviewRecord`/`EventRecord` `@Model`s and `SwiftDataUserDataStore` from `app-foundation`; `PersistenceConfig.cloudKitEnabled`; container id `iCloud.com.toffguy.lorito`.
- **No new dependencies, no custom backend**: sync is entirely Apple's CloudKit via SwiftData.
