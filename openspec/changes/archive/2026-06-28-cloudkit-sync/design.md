## Context

`bootstrap-foundation` made the persistence layer CloudKit-ready but kept sync off: the SwiftData `@Model` records (`SettingsRecord`, `ReviewRecord`, `EventRecord`) all have defaulted properties and no unique constraints (CloudKit requirements); `PersistenceController.makeContainer` already accepts `PersistenceConfig.cloudKitEnabled` and builds the `ModelConfiguration` with `.private(containerID)` when set; and `Lorito.entitlements` declares the `iCloud.com.toffguy.lorito` container — but the entitlement is not wired into `project.yml` and `cloudKitEnabled` defaults to `false`. The app is now live on the App Store (1.0.1) as local-only.

This change activates sync through the user's **private** CloudKit database (no shared/public data, no custom server). It is an app/persistence-layer change; the pure `Domain` layer is untouched.

## Goals / Non-Goals

**Goals:**
- Per-user progress (reviews, settings, study log) converges across devices signed into the same Apple ID.
- Wire the iCloud capability, entitlement, and container into the build and signing.
- Graceful local-only operation when no iCloud account is available, converging later with no data loss.
- Deterministic merge of concurrent edits; no duplicated cards, no lost study log.
- Existing v1 local data migrates into CloudKit on first sync.

**Non-Goals:**
- Any custom backend, shared/public CloudKit databases, or cross-user data.
- New screens or a sync-settings UI beyond minimal account-state surfacing.
- Changing the `Domain` model or the SM-2 / daily-plan / scheduling logic.
- Conflict UI or manual merge resolution (automatic LWW is sufficient for this data).

## Decisions

- **Private CloudKit DB via SwiftData's `.private(containerID)`.** Reuse the existing `PersistenceController` path; no manual `CKRecord` code. Rationale: the models are already SwiftData and CloudKit-safe; SwiftData+CloudKit handles mirroring, push, and merge. *Alternative — hand-rolled CloudKit* rejected as redundant and error-prone.
- **`cloudKitEnabled` resolved at startup, not hard-coded.** Enable when the build carries the entitlement (Release) and an iCloud account is available; otherwise fall back to a local store. Rationale: dev/test/host builds and signed-out users must still run. *Alternative — always on* rejected (breaks unsigned/test/simulator-without-account runs).
- **Local-first fallback with later convergence.** If CloudKit is unavailable at launch, open a local container; when an account appears, SwiftData mirrors local rows up and remote rows down. Rationale: never block studying on network/account. The records' defaulted, constraint-free shape makes the local↔cloud schema identical, so migration is upload-on-first-sync, not a conversion.
- **Last-writer-wins per record.** For `CardReview` and `UserSettings`, the most recent edit wins at field/record granularity (SwiftData+CloudKit default). Rationale: this is single-user data edited rarely on two devices; LWW is correct enough and needs no UI. `StudyLog` events are append-only with UUID ids, so they union rather than conflict.
- **`didCompleteOnboarding` stays local (`@AppStorage`).** First-run gating remains a local decision (already implemented) to avoid sync-timing flicker; synced `UserSettings.didCompleteOnboarding` is informational. Rationale: consistent with the onboarding change's decision.
- **Signing carries the entitlement.** The App ID gains the iCloud capability + container, and the distribution provisioning profile is regenerated to include it (via the existing fastlane signing path). Rationale: an entitlement not present in the profile fails App Store upload/validation.

## Risks / Trade-offs

- **Profile/entitlement mismatch breaks CI builds** → regenerate the App Store profile after enabling the iCloud capability on the App ID; verify a signed build validates before tagging a release.
- **Schema changes later are constrained by CloudKit** (no required properties, no unique constraints, additive only) → document the rule; the current models already comply.
- **Initial sync latency / partial hydration** on a fresh device → the daily plan recomputes as records arrive (the planner is pure and re-invoked), so the queue fills in as data syncs; surface a subtle "syncing" state rather than blocking.
- **Signed-out or restricted iCloud** → detect account status, run local-only, and converge on sign-in; never error out.
- **Testability**: CloudKit can't run in the `swift test` host. Keep all sync behind `PersistenceConfig`/account-state checks so Domain and store logic stay unit-testable with an in-memory/local container; CloudKit paths are verified manually on-device.
