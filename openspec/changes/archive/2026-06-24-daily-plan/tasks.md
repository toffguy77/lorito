## 1. Inputs & Value Types (Domain, pure)

- [x] 1.1 Define the planner input value types: a read-only content snapshot view (per card: `id`, `level`, `theme`, `order`, `related`), the current `CardReview` states keyed by card id, and the relevant `UserSettings` (`targetLevel`, `selectedThemes`, `dailyNewCardCount`, plus the max-reviews-per-day cap)
- [x] 1.2 Define the planner output types: the ordered queue (entries tagged due vs new) and the count report (due count, new count, empty flag, scope-exhausted flag)
- [x] 1.3 Define the injected "today" parameter type and the level-inclusion helper (target level plus all lower levels per `A1<A2<B1<B2<C1<C2`)
- [x] 1.4 Confirm the module stays pure: no SwiftUI / SwiftData / CloudKit imports in the planner and its types

## 2. Due Selection (TDD)

- [x] 2.1 Write failing tests: due `review` card included; due `learning` card included; not-yet-due card excluded; `suspended` excluded; no-state card not due
- [x] 2.2 Implement DUE selection (`dueDate ≤ today`, status `review`/`learning`, exclude `suspended`, exclude no-state)
- [x] 2.3 Write failing tests + implement deterministic due ordering: `dueDate` ascending, then `id` ascending

## 3. New Selection — Scope & Limit (TDD)

- [x] 3.1 Write failing tests: above-target-level card excluded; lower-level card in scope; out-of-`selectedThemes` card excluded; already-reviewed card not new
- [x] 3.2 Implement NEW eligibility (no review state, included level, theme in `selectedThemes`)
- [x] 3.3 Write failing tests + implement ascending-`order` introduction and the `dailyNewCardCount` limit (including fewer-eligible-than-limit)

## 4. New Selection — Related Prerequisites (TDD)

- [x] 4.1 Write failing tests: in-scope unreviewed prerequisite blocks its dependent the same day; already-learned prerequisite does not block; out-of-scope prerequisite does not block; dependent + prerequisite both admitted in dependency order when the limit allows
- [x] 4.2 Implement prerequisite gating: prerequisites = `related ∩ selection`, satisfied if already has review state or introduced earlier in the same plan
- [x] 4.3 Add defensive cycle handling for `related` within a selection (break cycles by ascending `order` so introduction always progresses); test that a cycle does not starve the planner

## 5. Reviews Cap & Overflow (TDD)

- [x] 5.1 Write failing tests: due under cap all admitted; overflow deferred (exact admitted count); deferred cards' scheduling state unchanged; default cap applies when none configured; most-overdue admitted first
- [x] 5.2 Implement the configurable max-reviews-per-day cap with the sensible default and overflow-by-omission (no scheduling mutation)

## 6. Assembly, Ordering & Edge Cases (TDD)

- [x] 6.1 Write failing tests + implement queue assembly: due cards before new cards in the returned order
- [x] 6.2 Write failing tests + implement deterministic tie-breaking end-to-end (equal `dueDate` → `id`; equal `order` → `id`)
- [x] 6.3 Write failing tests + implement the empty-queue case (nothing due + nothing new → empty queue, zero counts, empty flag)
- [x] 6.4 Write failing tests + implement the selection-exhausted case (all in-scope cards already introduced → due-only queue, new count 0, scope-exhausted flag)
- [x] 6.5 Write a determinism property test: shuffling the input collections yields an identical queue and counts

## 7. Count Report & Recomputation Contract (TDD)

- [x] 7.1 Write failing tests + implement the count report so its due/new counts equal the composed queue's, with empty and scope-exhausted flags
- [x] 7.2 Verify counts are obtainable for `reminders` without walking the full queue (shared selection pass)
- [x] 7.3 Write tests for the recomputation triggers as re-invocation: day rollover surfaces newly-due cards; settings change reflects new scope/limits; grade-driven `CardReview` change reflects updated membership

## 8. Validation

- [x] 8.1 Run the full planner test suite; confirm all scenarios in the spec are covered and green
- [x] 8.2 Run `openspec validate daily-plan --strict` and fix until it passes
