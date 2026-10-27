## Context

- Container `iCloud.com.toffguy.lorito`, team `3GWRDGA8B7` (project.yml).
- `PersistenceController` builds a SwiftData `ModelContainer` with
  `.private(containerID)` when CloudKit is enabled. SwiftData creates/extends the
  development schema when a debug build syncs.
- Apple's cktool supports `export-schema` for development and production,
  `import-schema` and `reset-schema` for development only; production deployment
  is done in CloudKit Console ([Using cktool](https://developer.apple.com/icloud/ck-tool)).

## Goals / Non-Goals

**Goals:** no release ships a synced field that production lacks; schema changes
are reviewable in git; the convention is written once and referenced by every
change.

**Non-Goals:** automating the production deploy (not possible with cktool);
destructive schema edits (CloudKit production schemas are additive only).

## Decisions

**Committed schema file.** After a change adds synced data, the developer runs a
debug build with CloudKit on (or `try container.initializeCloudKitSchema()` from a
debug-only launch argument `-LoritoInitCloudKitSchema`), then
`xcrun cktool export-schema --team-id 3GWRDGA8B7 --container-id iCloud.com.toffguy.lorito --environment development --output-file cloudkit/schema.ckdb`.
The diff is part of the change's PR.

**Gate script.** `tools/cloudkit_schema_check.sh` exports both environments to a
temp dir and compares record types and field names (text diff of the `.ckdb`
declarations). Exit 1 lists what production lacks. Fastlane `ci_release` and
`submit` call it first; `ci_beta` only warns (TestFlight builds use production too,
so the warning is loud).

**Additive only.** Fields are never renamed or removed in production; a renamed
Swift property keeps its stored name via `@Attribute(originalName:)`.

## Risks / Trade-offs

- [Developer forgets to export] → the gate compares live environments, not the
  file, so it still catches the missing deploy.
- [Management token in repo secrets] → read from the keychain by cktool; the file
  stays git-ignored.

## Migration Plan

Export today's development and production schemas once and commit the
development one as the baseline. Run the gate before the next release.
