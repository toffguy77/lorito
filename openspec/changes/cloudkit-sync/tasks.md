## 1. Capability & signing

- [ ] 1.1 Enable the iCloud capability + CloudKit service on the App ID and add the `iCloud.com.toffguy.lorito` container in App Store Connect / Developer Portal
- [x] 1.2 Wire `Lorito.entitlements` into the Lorito target in `project.yml` via `CODE_SIGN_ENTITLEMENTS`; regenerate the project and confirm a local signed build picks up the entitlement
- [ ] 1.3 Regenerate the App Store distribution provisioning profile so it carries the iCloud entitlement (via the existing fastlane signing path)

## 2. Runtime enablement

- [x] 2.1 Resolve `PersistenceConfig.cloudKitEnabled` at startup: on when the entitlement is present and an iCloud account is available, off otherwise (dev/test/simulator-without-account fall back to local)
- [x] 2.2 Build the `ModelContainer` with `.private("iCloud.com.toffguy.lorito")` when enabled; open a local container otherwise, using the identical schema so data is portable
- [x] 2.3 Detect iCloud account status at launch and expose it to the app (available / unavailable) without blocking the UI

## 3. Sync behavior & merge

- [ ] 3.1 Verify SwiftData+CloudKit mirrors `SettingsRecord`/`ReviewRecord`/`EventRecord` to the private DB and merges remote changes into the running context
- [ ] 3.2 Confirm last-writer-wins resolution for `CardReview`/`UserSettings` and union (no duplicates) for UUID-keyed `StudyLog` events
- [ ] 3.3 Ensure the daily plan recomputes as records arrive (re-invoke the pure planner on store change) so a fresh device fills its queue progressively

## 4. Local-only fallback & migration

- [x] 4.1 When no iCloud account is available, run on the local container and keep all features working
- [ ] 4.2 On sign-in / account becoming available, converge local and remote data with no loss (upload local rows, merge remote rows)
- [ ] 4.3 Verify a v1 local-only user's existing data is uploaded on first sync rather than reset
- [x] 4.4 Keep `didCompleteOnboarding` first-run gating local (`@AppStorage`) to avoid sync-timing flicker

## 5. Verification

- [ ] 5.1 Unit tests stay green using a local/in-memory container (no CloudKit dependency in `swift test`); add coverage for the `cloudKitEnabled` resolution logic
- [ ] 5.2 On-device manual check: grade on device A, confirm it appears on device B; sign-out path runs local-only; sign-in converges
- [ ] 5.3 Build, sign, and validate a Release IPA with the iCloud entitlement (no upload errors)
- [ ] 5.4 Run `openspec validate cloudkit-sync --strict` and fix until valid
