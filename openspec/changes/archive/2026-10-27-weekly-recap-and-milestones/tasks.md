## 0. Dependencies

- [x] 0.1 `learning-platform-foundation` applied (local learning day, `ItemKind`)
- [x] 0.2 `progress-insights` applied (long-term memory by level); `cloudkit-schema-release` applied
- [x] 0.3 Optional: `personal-traps` applied (it is) (top trap source); otherwise use the Опять fallback

## 1. Monday weeks (TDD)

- [x] 1.1 Write failing tests: "studied this week" uses Monday–Sunday (Sunday belongs to the ending week; Monday starts at 0)
- [x] 1.2 Set `firstWeekday = 2` on the stats calculator's calendar; existing stats tests updated where they assumed Sunday weeks

## 2. Domain (TDD)

- [x] 2.1 Write failing tests for `WeeklyRecap.make`: latest completed Monday–Sunday week; days studied; new rules counting only `.card` items; current long-term count; top trap and fallback; empty week; determinism
- [x] 2.2 Write failing tests for `LevelMilestones.newlyClosed`: all non-suspended `.card` items long-term; included levels only; excludes celebrated
- [x] 2.3 Write failing tests for celebrated-levels union encode/decode/merge (commutative, idempotent)
- [x] 2.4 Implement

## 3. Persistence

- [x] 3.1 Optional scalars `lastRecapWeek` and `celebratedLevels` (sorted codes) on the settings record, mapped both ways; union applied on write and on incoming sync in `SwiftDataUserDataStore`
- [x] 3.2 Store round-trip test and two-device union test; export dev schema per `cloudkit-schema-release` — (owner): `-LoritoInitCloudKitSchema` + `cktool export-schema` (SettingsRecord.lastRecapWeek, celebratedLevels)

## 4. Features

- [x] 4.1 Today recap card from Monday for the completed week, once; encouraging empty state
- [x] 4.2 Milestone celebration "A1 закрыт" with share; adds the level to the celebrated set
- [x] 4.3 Share images (9:16, `ImageRenderer`, `ShareLink`) limited to brand mark, numbers/level, month and year; view-model test for no personal data

## 5. Validation

- [x] 5.1 `swift test` green
- [x] 5.2 `xcodebuild` build; UI test with seeded data: recap on Monday once; milestone once (UI test shows both from a seeded store; "once" is covered by WeeklyRecapFeatureTests since UI-testing launches start fresh)
- [x] 5.3 Release note: "this week" counts now run Monday–Sunday
- [x] 5.4 `openspec validate weekly-recap-and-milestones --strict`
