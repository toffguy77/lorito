## 1. Domain Types & Constants

- [x] 1.1 Define the `Domain` grade type with exactly four cases (again/hard/good/easy) mapped to the UI labels Опять/Трудно/Хорошо/Легко
- [x] 1.2 Define a `Domain` value type for review state mirroring the foundation `CardReview` fields (easeFactor, interval, repetitions, dueDate, lastGrade, status) without importing SwiftData/CloudKit
- [x] 1.3 Define named scheduler constants (ease floor ≈1.3, default ease, ease deltas for again/hard/good/easy, initial good/easy intervals, easy bonus, hard factor, relearn step) — no magic numbers
- [x] 1.4 Define a clock/calendar injection seam (a "today" input with whole-day granularity) used by the scheduler

## 2. Scheduler (TDD — write tests first)

- [x] 2.1 Write failing tests: same inputs (state, grade, today) produce identical output; output never depends on wall-clock time
- [x] 2.2 Write failing tests: first review of a `new` card — `good` sets repetitions 1 and a short interval; `easy` > `good` interval; card leaves `new`
- [x] 2.3 Write failing tests: `again` resets repetitions to 0, sets status `learning`, schedules a short relearn interval (due same/next day), lowers ease but not below floor; also for a lapsing `review` card
- [x] 2.4 Write failing tests: `learning` graduates to `review` on `good`/`easy` and increments repetitions; a `learning` card never returns to `new`
- [x] 2.5 Write failing tests: ease floor — repeated `hard`/`again` clamps easeFactor to ≈1.3 and never below
- [x] 2.6 Write failing tests: `review` + `good` interval ≈ interval × easeFactor, dueDate = today + interval, repetitions incremented, ease not decreased
- [x] 2.7 Write failing tests: `hard` yields smaller interval than `good` and lowers ease (clamped); `easy` yields larger interval than `good` and raises ease
- [x] 2.8 Write failing tests: `suspended` card — any grade is a no-op (all fields unchanged); suspended never selected as due even when dueDate ≤ today
- [x] 2.9 Write failing tests: dueDate = today + interval (whole days); two different "today" values shift dueDate by exactly their difference (clock injection)
- [x] 2.10 Implement the pure `schedule(state, grade, today)` function in `Domain` until all tests in 2.1–2.9 pass
- [x] 2.11 Confirm the scheduler/`Domain` module imports no SwiftUI, SwiftData, or CloudKit and reads no `Date.now`

## 3. Due Selection Helper

- [x] 3.1 Write failing tests: a card is "due" when status ∈ {learning, review} and dueDate ≤ today; `new` and `suspended` are handled per spec (suspended always excluded)
- [x] 3.2 Implement the pure due-selection predicate/helper in `Domain` until tests pass

## 4. Apply-and-Persist Integration

- [x] 4.1 Write failing tests (against a test/in-memory persistence double): grading a card with no existing `CardReview` initializes a `new` review, applies the scheduler, and persists it
- [x] 4.2 Write failing tests: grading a card with an existing `CardReview` loads it, applies the scheduler, and writes the updated review back
- [x] 4.3 Write a failing test asserting the pure scheduler performs no persistence I/O (it operates only on passed-in values)
- [x] 4.4 Implement the apply-and-persist operation that bridges `Domain` and the foundation persistence layer, referencing the existing `CardReview` model without redefining it, until tests in 4.1–4.3 pass

## 5. Validation & Wrap-up

- [x] 5.1 Verify all scenarios in `specs/srs-engine/spec.md` are covered by a test
- [x] 5.2 Run the full scheduler test suite and confirm it is green and deterministic (no flakiness across runs)
- [x] 5.3 Run `openspec validate srs-engine --strict` and fix issues until it reports the change is valid
