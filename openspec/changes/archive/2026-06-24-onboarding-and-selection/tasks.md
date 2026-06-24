## 1. Domain selection helpers (pure)

- [x] 1.1 Add `includedLevels(for targetLevel:)` returning the target and all lower levels per `content-model`'s ordered levels; no I/O.
- [x] 1.2 Add `inScopeThemes(for includedLevels:)` deriving the selectable themes from the per-level theme registry of the included levels.
- [x] 1.3 Add `inScopeCards(targetLevel:selectedThemes:)` returning cards whose level is included and whose theme is in the selected set.
- [x] 1.4 Add `isStudyable(targetLevel:selectedThemes:)` returning true iff the in-scope card set is non-empty.
- [x] 1.5 Unit-test all helpers: A1-only scope, B1 includes A1–B1, B2 includes A1–B2, theme filtering, empty-selection studyability false, determinism/no I/O.

## 2. Scope read/write through persistence

- [x] 2.1 Add a read of `UserSettings.targetLevel` and `UserSettings.selectedThemes` for the screens to consume.
- [x] 2.2 Add a write that persists target level and selected themes, gated by `isStudyable(...)` so a non-studyable selection is never persisted.
- [x] 2.3 On a persisted change, emit the `daily-plan` recompute trigger (reference the `daily-plan` contract; do not implement the planner).
- [x] 2.4 Add a local first-run completion flag with read/write.

## 3. Onboarding flow (Features)

- [x] 3.1 Build the target-level step using the design-system level/theme chip; selecting a level shows the auto-included lower levels.
- [x] 3.2 Disable the finish control until a target level is chosen and the resulting scope is studyable.
- [x] 3.3 Build the optional theme-narrowing step defaulting to all in-scope themes selected, offering only included-level themes.
- [x] 3.4 Apply the non-empty-scope guard before completing; block "deselect all" with Russian copy explaining at least one theme is required.
- [x] 3.5 On completion, persist scope, set the first-run flag, and route to the main flow.

## 4. First-run gating

- [x] 4.1 At launch, present onboarding only when the first-run flag is unset; otherwise open the main flow directly.
- [x] 4.2 Verify a relaunch after completion skips onboarding.

## 5. Settings screen (Features)

- [x] 5.1 Build a settings screen to change the target level; re-derive included levels and the selectable theme set on change.
- [x] 5.2 Build theme selection in settings scoped to the current included levels, applying the non-empty-scope guard.
- [x] 5.3 On a persisted change to level or themes, trigger the `daily-plan` recompute (referenced).
- [x] 5.4 Verify raising widens scope (and selectable themes) and lowering narrows scope (dropping out-of-scope themes).

## 6. Validation

- [x] 6.1 Run `openspec validate onboarding-and-selection --strict` and fix until it reports the change is valid.
