## 0. Dependencies

- [ ] 0.1 `learning-platform-foundation` (local learning day, first-grade-per-day memory updates, end-of-session re-show) and `cloudkit-schema-release` applied

## 1. Model (Domain, TDD)

- [ ] 1.1 Add optional `stability`, `difficulty`, `lastReviewDate`, `schedulerVersion`, `fsrsDueDate` to `ReviewState`
- [ ] 1.2 `FSRSParameters` with the 21 FSRS-6 defaults copied from a reference implementation (cite source in a comment) and `maxInterval = 365`; test pinning the values
- [ ] 1.3 Add `desiredRetention: Double = 0.9` (clamped 0.80–0.95) to `UserSettings`

## 2. Scheduler (Domain, TDD)

- [ ] 2.1 Write failing tests from the spec: determinism; four grades distinct; new-card init (easy > good ≥ hard); again → learning/interval 0/difficulty ≤ 10; learning + hard → learning, reps unchanged, ≥ 1 day; learning + good → review; retention 0.9 → interval == round(stability); 0.95 ≤ 0.9; elapsed days from `lastReviewDate`; ordering below cap; equality at cap; suspended no-op; max clamp
- [ ] 2.2 Cross-check: for 3–5 fixed review histories compare stability/difficulty with the reference implementation (tolerance 1e-3); fixtures committed
- [ ] 2.3 Implement `FSRSScheduler` (curve, stability/difficulty updates, interval inversion, ordering guard, clamps, sets `lastReviewDate`, `schedulerVersion = 2`, `fsrsDueDate`); keep `SpacedRepetitionScheduler` for rollback, unused
- [ ] 2.4 Write failing tests then implement `SM2Migration`: stability = max(interval, 1), ease → difficulty map, `lastReviewDate` = dueDate − interval when absent; new/suspended untouched
- [ ] 2.5 Write failing tests then implement the consistency check: version ≠ 2 or `fsrsDueDate` ≠ `dueDate` → re-migrate

## 3. Integration

- [ ] 3.1 Switch `GradingService` and `IntervalPreview` to `FSRSScheduler` with `desiredRetention`; update preview tests; allow equal captions at the cap
- [ ] 3.2 Persistence: new `ReviewRecord` and `SettingsRecord` optional/defaulted properties, mapped both ways in `SwiftDataUserDataStore`; store round-trip tests
- [ ] 3.3 Export the dev CloudKit schema to `cloudkit/schema.ckdb`; add production deploy to the release gate
- [ ] 3.4 Settings row «Целевая запоминаемость» (80/85/90/95%) with a one-line explanation
- [ ] 3.5 Regression: daily-plan due selection and stats tests unchanged and green

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test: grade buttons show ordered captions
- [ ] 4.3 Manual: upgrade an install with SM-2 data → studying works, due dates unchanged until graded; edit a card on an old build on a second device → re-migrated on the new build
- [ ] 4.4 `openspec validate fsrs-scheduler --strict`
