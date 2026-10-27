## 1. Baseline

- [ ] 1.1 _(owner — needs the management token from secrets/)_ On the Mac: `xcrun cktool save-token --type management` (token from `secrets/ck_management_token.txt`)
- [ ] 1.2 _(owner — commands in cloudkit/README.md)_ Export development and production schemas; commit development as `cloudkit/schema.ckdb`; record any existing dev-only fields in the PR
- [x] 1.3 Add debug-only launch argument `-LoritoInitCloudKitSchema` that calls `initializeCloudKitSchema()` (excluded from Release builds)

## 2. Gate

- [x] 2.1 `tools/cloudkit_schema_check.sh`: export both environments, compare record types and fields, exit 1 with a list of missing items
- [x] 2.2 Self-test with a fixture pair of `.ckdb` files (missing field → exit 1; equal → exit 0)
- [x] 2.3 Call it first in fastlane `ci_release` and `submit` (fail) and `ci_beta` (warn)

## 3. Convention

- [x] 3.1 Add a "Synced data checklist" to CLAUDE.md: optional/defaulted property, both-way mapping in `SwiftDataUserDataStore`, store round-trip test, export schema, deploy before release
- [x] 3.2 Round-trip test helper in PersistenceTests for settings fields

## 4. Release step (owner, or Claude via browser with approval)

- [ ] 4.1 _(owner)_ CloudKit Console → container `iCloud.com.toffguy.lorito` → «Deploy Schema Changes» → confirm the listed types/fields match `cloudkit/schema.ckdb`
- [ ] 4.2 _(owner, before submit)_ Re-run the gate; it must pass before `submit`

## 5. Validation

- [x] 5.1 `openspec validate cloudkit-schema-release --strict`
