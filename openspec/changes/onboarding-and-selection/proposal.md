## Why

Lorito ships 165 cards across six CEFR levels (A1–C2), but a learner does not start everywhere at once. On first launch the app must ask **what** the user wants to study: a target level (which auto-includes every lower level) and, optionally, a narrower set of themes within those included levels. Without this step the app has no defined study scope, so `daily-plan` cannot compose a queue.

The `bootstrap-foundation` change already defined where these choices live (`UserSettings.targetLevel`, `UserSettings.selectedThemes`) and the rules that govern levels and themes (`content-model`: six ordered levels where choosing a target auto-includes all lower levels; per-level theme registries grouping contiguous cards). What is missing is the behavior: a one-time onboarding flow that captures a valid scope, an ongoing settings screen to change it later, and the pure, testable scope logic that maps these choices to a concrete set of in-scope cards. This change adds exactly that, building on the foundation contracts without redefining them.

Keeping the selection logic — which levels are included, which themes are valid, which cards are in scope, and whether a selection is studyable — in pure `Domain` helpers means it can be unit-tested without a simulator and reused by `daily-plan`, while the screens live in `Features` using design-system components.

## What Changes

- Add a **first-run onboarding flow** (`Features`) shown only on the very first launch. The user picks a target level (A1–C2); selecting it auto-includes all lower levels per `content-model` and persists to `UserSettings.targetLevel`. A target level MUST be chosen before onboarding can finish.
- Add **theme selection**: within the included levels the user may optionally narrow which themes to study. The default is all themes in scope selected. The choice persists to `UserSettings.selectedThemes`.
- Add an **ongoing settings screen** that lets the user change the target level and theme selection at any time after onboarding. Raising or lowering the level re-scopes the included content (and re-scopes the set of selectable themes accordingly); changing the selection triggers a `daily-plan` recompute (referenced, not implemented here).
- Define a **non-empty-scope guard**: the system MUST prevent any selection that would yield zero studyable cards (for example, deselecting every theme). Both onboarding and settings enforce this guard before persisting.
- Define **first-run detection**: onboarding is shown exactly once; once completed, subsequent launches open directly to the main flow.
- Add pure **`Domain` selection helpers**: included-levels from a target level, in-scope themes for the included levels, in-scope cards for a (target level, selected themes) pair, and a studyability predicate — all pure and unit-testable.

This change delivers the onboarding and settings screens plus the scope logic. It does not implement the daily-queue planner (that is `daily-plan`) and does not include practice exercises.

## Capabilities

### New Capabilities
- `onboarding-and-selection`: First-run onboarding and ongoing settings for choosing the study scope — target-level selection (auto-including lower levels), optional theme narrowing within included levels, persistence to `UserSettings.targetLevel`/`UserSettings.selectedThemes`, the non-empty-scope guard, one-time first-run gating, and the pure `Domain` helpers that derive included levels, in-scope themes, and in-scope cards and decide studyability. Changing the scope from settings triggers a `daily-plan` recompute.

### Modified Capabilities
<!-- None — the foundation specs (app-foundation, content-model, content-pipeline, design-system) are not archived yet, so this change introduces no MODIFIED deltas. It builds on the foundation's UserSettings model and content-model level/theme rules without redefining them. -->

## Impact

- **Code (added, not in scope to author here)**: onboarding and settings screens in the `Features` layer using design-system components (the level/theme chip in particular); pure scope helpers in the `Domain` layer plus their unit tests; a small read/write of `UserSettings` and a first-run flag through the existing `Persistence` layer.
- **Foundation contracts consumed (not modified)**: `UserSettings.targetLevel` and `UserSettings.selectedThemes` from `app-foundation`; the six ordered levels and the "target auto-includes lower levels" rule plus the per-level theme registry from `content-model`; the level/theme chip from `design-system`.
- **Adjacent change (referenced, not implemented)**: `daily-plan` recomputes the daily queue from the included levels and `selectedThemes`; a scope change made here must trigger that recompute.
- **No new dependencies, no backend, no schema changes**: choices are stored in the already-defined `UserSettings` fields; the first-run flag is local app state.
