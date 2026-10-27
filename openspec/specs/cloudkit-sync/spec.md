# cloudkit-sync Specification

## Purpose
TBD - created by archiving change cloudkit-sync. Update Purpose after archive.
## Requirements
### Requirement: iCloud capability wired into the build
The app SHALL ship with the iCloud/CloudKit capability and the `iCloud.com.toffguy.lorito` container declared in its entitlements and applied to the app target at build time, so a signed build is authorized to use CloudKit.

#### Scenario: Entitlement present in a signed build
- **WHEN** a Release build of the app is produced
- **THEN** it carries the iCloud container entitlement for `iCloud.com.toffguy.lorito` and passes App Store validation

#### Scenario: Container identifier matches the foundation
- **WHEN** the CloudKit container is configured
- **THEN** it is `iCloud.com.toffguy.lorito` as defined by the foundation

### Requirement: Progress syncs across devices via the private database
With iCloud available, the app SHALL store and synchronize per-user progress — `CardReview` scheduling state, `UserSettings`, and `StudyLog` — through the user's private CloudKit database, with no custom backend.

#### Scenario: Edit on one device appears on another
- **WHEN** the user grades a card on device A and later opens the app on device B signed into the same Apple ID
- **THEN** device B reflects the updated `CardReview` state for that card after sync

#### Scenario: Settings sync
- **WHEN** the user changes target level or selected themes on one device
- **THEN** the updated `UserSettings` is reflected on the other device after sync

#### Scenario: Study log unions across devices
- **WHEN** cards are studied on two devices on the same day
- **THEN** the combined `StudyLog` contains the events from both devices without duplication

### Requirement: Local-first operation without an iCloud account
The app SHALL remain fully usable when the user is not signed into iCloud or CloudKit is unavailable, storing progress locally and SHALL converge with CloudKit once an account becomes available, without data loss.

#### Scenario: No iCloud account
- **WHEN** the app launches and no iCloud account is available
- **THEN** the app works entirely locally and presents no blocking error

#### Scenario: Convergence after sign-in
- **WHEN** the user signs into iCloud after having studied locally
- **THEN** the locally stored progress is uploaded to CloudKit and any existing remote progress is merged in, with no loss

### Requirement: Deterministic merge of concurrent edits
When the same record is edited on more than one device, the app SHALL resolve the conflict deterministically (last writer wins per record) so the result is consistent across devices, and SHALL NOT duplicate cards or drop study-log events.

#### Scenario: Concurrent edits to the same card
- **WHEN** the same `CardReview` is updated on two devices and both sync
- **THEN** both devices converge to the same single record (the most recent edit) with no duplicate

### Requirement: Migration of existing local data
On the first launch with sync enabled for a user who already has local-only progress, the app SHALL upload the existing local data to CloudKit rather than resetting it.

#### Scenario: Existing local data is preserved
- **WHEN** a v1 user with local progress updates to the sync-enabled build and signs into iCloud
- **THEN** their existing reviews, settings, and study log are uploaded to CloudKit and remain intact

### Requirement: Sync does not block studying
Sync activity SHALL NOT prevent the user from studying. On a fresh device the daily plan SHALL compose from whatever records have synced so far and SHALL update as more records arrive.

#### Scenario: Studying during initial sync
- **WHEN** the app is opened on a new device while CloudKit data is still arriving
- **THEN** the Today screen is usable and its queue/counts update as records finish syncing

### Requirement: Synced data is additive and defaulted
Every field or record added to the synced store SHALL be optional or have an inline default, SHALL be mapped in both directions between the persistence record and its Domain value, and SHALL be covered by a store round-trip test. Fields SHALL NOT be removed or renamed in storage; composite values SHALL be stored as scalar fields.

#### Scenario: Old record loads with defaults
- **WHEN** a settings record saved by an older app version is loaded by a version that added a field
- **THEN** the new field takes its default and the load succeeds

#### Scenario: Round trip keeps new fields
- **WHEN** settings with a new field set are saved and loaded through the store
- **THEN** the loaded value equals the saved value

### Requirement: Committed development schema
The repository SHALL contain the CloudKit development schema exported as `cloudkit/schema.ckdb`, and every change that adds synced data SHALL update that file in the same change.

#### Scenario: Schema change is visible in review
- **WHEN** a change adds a synced field
- **THEN** its diff includes the corresponding update to `cloudkit/schema.ckdb`

### Requirement: Production schema release gate
Release lanes SHALL run a check that compares the development and production CloudKit schemas and SHALL stop the release when production lacks any record type or field present in development, listing what is missing. The production schema SHALL be deployed through CloudKit Console before the release proceeds.

#### Scenario: Missing deploy blocks release
- **WHEN** development has a field that production lacks and the release lane runs
- **THEN** the lane fails and names the missing field

#### Scenario: Deployed schema passes
- **WHEN** production contains every development record type and field
- **THEN** the check passes and the release continues

