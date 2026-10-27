## Why

Lorito syncs progress through the user's private CloudKit database. CloudKit keeps
two schemas per container: **development** (changes automatically while we run
debug builds) and **production** (what App Store users get, changed only by an
explicit "Deploy Schema Changes"). If a release adds a SwiftData field or record
that is not deployed to production, sync for that data silently fails on users'
devices. Twelve roadmap changes add synced fields or records (fsrs-scheduler,
study-goal, personal-traps, vocabulary-decks, conjugation-trainer,
regional-variants, spanish-audio, weekly-recap-and-milestones, placement-test,
exam-path-dele-ccse, product-analytics if any synced field, study-buddy). Today
this depends on someone remembering a console click. This change turns it into a
repeatable, checked release step and a coding convention.

## What Changes

- **Convention for synced data:** every new field is an optional or
  inline-defaulted `@Model` property, mapped both ways in
  `SwiftDataUserDataStore`, covered by a store round-trip test; structs are
  flattened into scalar fields.
- **Schema as a file:** the development schema is exported with `xcrun cktool`
  to `cloudkit/schema.ckdb` and committed, so schema changes show up in review.
- **Release gate:** `tools/cloudkit_schema_check.sh` exports the production
  schema and fails when development has record types or fields that production
  lacks; fastlane release lanes run it before upload.
- **Deployment step:** the owner (or Claude through the browser, with the owner's
  approval) presses «Deploy Schema Changes» in CloudKit Console; `cktool` cannot
  deploy to production.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `cloudkit-sync`: adds the synced-field convention, the committed schema file,
  and the release gate.

## Impact

- New `cloudkit/schema.ckdb`, `tools/cloudkit_schema_check.sh`, fastlane lane hook.
- Uses the existing CloudKit management token (`secrets/ck_management_token.txt`,
  saved to the keychain with `xcrun cktool save-token --type management`).
- macOS only (cktool ships with Xcode); not run in the Linux content pipeline.
