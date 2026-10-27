## 1. Model (Domain, TDD)

- [ ] 1.1 Write failing tests: `ReviewState` decodes old data without `stability`/`difficulty`; new optional fields round-trip
- [ ] 1.2 Add optional `stability`, `difficulty` to `ReviewState`; `FSRSParameters` with the 21 FSRS-6 defaults copied from a reference implementation (cite source in a comment) and `maxInterval = 365`; test pinning the values
- [ ] 1.3 Add `desiredRetention: Double = 0.9` to `UserSettings` (range-clamped 0.80–0.95); decode test for old settings

## 2. Scheduler (Domain, TDD)

- [ ] 2.1 Write failing tests from the spec: determinism, four grades distinct, new-card initialisation (easy > good ≥ hard), again → learning/interval 0/difficulty ≤ 10, retention 0.9 → interval == round(stability), 0.95 ≤ 0.9 interval, ordering again ≤ hard ≤ good < easy over a grid of states, suspended no-op, max interval clamp
- [ ] 2.2 Cross-check against reference values: for 3–5 fixed review histories, compare stability/difficulty with the reference implementation's output (tolerance 1e-3) — fixtures generated once and committed
- [ ] 2.3 Implement `FSRSScheduler` (retrievability curve, stability/difficulty updates incl. same-day rule, interval inversion, ordering guard, clamps); keep `SpacedRepetitionScheduler` for rollback, unused
- [ ] 2.4 Write failing tests then implement `SM2Migration.memoryState(from:)`: stability = max(interval, 1), ease→difficulty linear map clamped 1–10, new/suspended untouched

## 3. Integration

- [ ] 3.1 Switch `GradingService` and `IntervalPreview` to `FSRSScheduler`, passing `desiredRetention`; existing preview tests updated to FSRS values, ordering test added
- [ ] 3.2 SwiftData record: add optional `stability`, `difficulty`; mapping both ways; persistence round-trip test
- [ ] 3.3 CloudKit: verify the new fields sync in development; note the production schema deploy step in release checklist
- [ ] 3.4 Settings row «Целевая запоминаемость» (stepper or segmented 80/85/90/95%) with one-line explanation
- [ ] 3.5 Regression: daily-plan due selection and stats tests unchanged and green

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test: grade buttons still show ordered captions
- [ ] 4.3 Manual: upgrade an install with SM-2 data → studying works, due dates unchanged until graded
- [ ] 4.4 `openspec validate fsrs-scheduler --strict`
