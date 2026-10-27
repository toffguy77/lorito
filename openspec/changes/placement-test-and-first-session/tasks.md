## 0. Dependencies

- [x] 0.1 `learning-platform-foundation` applied (learning day, new-introduction budget, `CardBodyParser` in Domain)
- [x] 0.2 `cloudkit-schema-release` applied (schema workflow); `product-analytics` applied (event enum)

## 1. Domain: placement algorithm (TDD)

- [x] 1.1 Write failing tests for block selection: 3 per level, A2 first, distinct themes where possible, no repeats, no stop inside a block, determinism with injected seed
- [x] 1.2 Write failing tests for pass/stop: ≥ 2/3 passes; climb after pass; stop after a failed level or C2 pass; A2 fail → one A1 block then stop; < 2 usable exercises → untestable level
- [x] 1.3 Write failing tests for proposal/known levels: A2 3/3 + B1 1/3 → target B1, known A1–A2; nothing passed → A1, none known; C2 passed → C2
- [x] 1.4 Write failing tests for traps (first mistakes item per failed card, max 3, newest first) and the seeding plan (only correct answers at known levels; state = scheduler result for Хорошо on a new card)
- [x] 1.5 Implement `PlacementTest` + `PlacementConstants`

## 2. Daily plan (TDD)

- [x] 2.1 Write failing tests: with `placementKnownLevel` set, higher-level new cards first, then known levels in order; unset → unchanged
- [x] 2.2 Implement the ordering in the composer

## 3. Persistence

- [x] 3.1 `UserSettings.placementKnownLevel` as an optional scalar record field, mapped both ways in `SwiftDataUserDataStore`; store round-trip test; export dev schema per `cloudkit-schema-release` — (owner): `-LoritoInitCloudKitSchema` run + `cktool export-schema` (new `SettingsRecord.placementKnownLevelRaw`)
- [x] 3.2 Seeding writes `CardReview` only; store test: no `StudyEvent`, streak unchanged, budget unchanged

## 4. Features

- [x] 4.1 Onboarding order: level (manual / test) → themes → reminders, with no goal or variant step; UI test asserts the order
- [x] 4.2 Test flow screen (focus surfaces) and result screen: proposal pre-selected, "ваши 3 ловушки", «Пропустить то, что я знаю» toggle, accept / choose another
- [x] 4.3 First-session hand-off: one-off allowance max(3, dailyNewCardCount) within the budget, failed-test cards first, never on relaunch
- [x] 4.4 Today prompt slot after the first completed session (goal / variant prompts provided by `study-goal` and `regional-variants`), one per visit, dismissible
- [x] 4.5 Emit `placementStarted`, `placementCompleted`, `placementSkipKnownApplied`, `firstSessionStarted`

## 5. Validation

- [x] 5.1 `swift test` green
- [x] 5.2 `xcodebuild` build; UI test: fresh install → test with scripted answers → accept B1 → session opens with 3 new cards, B1 first
- [x] 5.3 UI test: manual path completes onboarding; relaunch lands on Today (UI-testing launches always start fresh, so the test covers background → foreground; a cold relaunch is manual)
- [x] 5.4 `openspec validate placement-test-and-first-session --strict`
