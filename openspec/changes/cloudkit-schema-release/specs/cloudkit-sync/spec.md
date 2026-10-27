## ADDED Requirements

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
