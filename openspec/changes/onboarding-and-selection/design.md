## Context

`bootstrap-foundation` established the contracts this change builds on: `content-model` defines six ordered levels (A1 < A2 < B1 < B2 < C1 < C2) where choosing a target level auto-includes all lower levels, and per-level theme registries that group contiguous cards; `app-foundation` defines `UserSettings` with `targetLevel` and `selectedThemes` (plus `reminderConfig` and `dailyNewCardCount`, out of scope here), persisted via SwiftData and synced through the user's private CloudKit DB; `design-system` provides a level/theme chip component. The adjacent `daily-plan` change composes the daily queue from the included levels and `selectedThemes` and must recompute when that scope changes.

This change supplies the missing behavior: a one-time onboarding flow to capture a valid initial scope, an ongoing settings screen to change it, and the pure scope logic that ties user choices to a concrete in-scope card set. The 165 cards are bundled offline; UI copy is in Russian. No backend is introduced.

## Goals / Non-Goals

Goals:
- Capture a valid study scope on first run: a required target level (auto-including lower levels) and an optional theme narrowing, persisted to `UserSettings`.
- Let the user change that scope later from a settings screen, re-scoping content and triggering a `daily-plan` recompute.
- Guarantee the persisted scope always yields at least one studyable card.
- Keep all selection logic (included levels, in-scope themes, in-scope cards, studyability) in pure, unit-testable `Domain` helpers shared with `daily-plan`.
- Show onboarding exactly once.

Non-Goals:
- Implementing the daily-queue planner or SRS scheduling (`daily-plan`, `srs-engine`).
- Practice exercises (explicitly out of scope).
- Defining or modifying the `UserSettings`, `CardReview`, or content models (owned by the foundation).
- Per-card selection, custom ordering, or scheduling preferences beyond level and themes.

## Decisions

### Decision: Selection logic lives in pure Domain helpers
All "what is in scope" computation is implemented as pure functions in `Domain` (no SwiftUI/SwiftData/CloudKit imports): `includedLevels(for:)`, `inScopeThemes(for:)`, `inScopeCards(targetLevel:selectedThemes:)`, and `isStudyable(...)`. Onboarding, settings, the non-empty-scope guard, and `daily-plan` all call the same helpers.
- Rationale: a single source of truth for scope avoids drift between onboarding, settings, and the planner; pure functions are exhaustively unit-testable without a simulator and keep `Domain` portable per the foundation's layer rules.
- Alternative considered: computing scope inside the view models. Rejected — it would duplicate the rule across screens and `daily-plan` and make it untestable in isolation.

### Decision: target level is the primary input; themes are a sub-filter of it
The level choice determines included levels first; the selectable theme set is derived from those included levels, and `selectedThemes` is always interpreted against the current included levels.
- Rationale: matches `content-model`, where themes belong to levels and a target auto-includes lower levels. Changing the level therefore necessarily re-derives the valid theme set.
- Alternative considered: treating themes as a free-standing global selection independent of level. Rejected — it could persist themes for excluded levels, producing confusing or empty scopes and complicating the guard.

### Decision: store `selectedThemes` as an explicit set; "all selected" is the default, not a sentinel
On reaching theme selection the default is every in-scope theme selected, persisted explicitly. When the level changes and widens the included set, newly in-scope themes are treated as selected by default so widening the level never silently leaves new themes out; when the level narrows, themes no longer in scope are dropped from the persisted set.
- Rationale: predictable, inspectable persisted state; avoids an ambiguous "empty means all" sentinel that the guard would have to special-case.
- Alternative considered: empty `selectedThemes` meaning "all themes." Rejected — it collides with the non-empty-scope guard's notion of an empty selection and makes intent ambiguous.

### Decision: non-empty-scope guard is enforced at persistence boundaries via the studyability helper
Before persisting any scope change (onboarding completion or a settings edit), the flow calls `isStudyable(...)`. If false, the change is not persisted, no `daily-plan` recompute is triggered, and the UI prevents proceeding (the confirm/finish control is unavailable and at least one card-contributing theme must be selected).
- Rationale: centralizes the invariant "the persisted scope is always studyable" at the single write boundary rather than scattering checks through the UI.
- Alternative considered: validating only at read time in `daily-plan`. Rejected — it would allow persisting an unusable scope and push error handling downstream into the planner.

### Decision: first-run gating uses a local completion flag, not the presence of settings
Onboarding completion is tracked by an explicit local flag rather than inferring "has the user picked a level." 
- Rationale: a target level always exists conceptually, and inferring completion from synced settings risks re-showing or wrongly skipping onboarding during CloudKit sync timing. A local flag keeps first-run a deterministic local decision.
- Alternative considered: "show onboarding if `targetLevel` is unset." Rejected — depends on sync state and a not-yet-set default, which is fragile across devices and launches.

### Decision: settings changes trigger a daily-plan recompute (referenced)
A persisted change to `targetLevel` or `selectedThemes` from settings signals `daily-plan` to recompute the queue. This change only references that contract and emits the trigger; it does not implement the planner.
- Rationale: keeps responsibilities separated per the roadmap while ensuring the visible plan reflects the new scope.

## Risks / Trade-offs

- **Level/theme registry coupling**: the helpers depend on the `content-model` theme registry; if a level has themes but zero loadable cards, studyability could be falsely true. Mitigation: studyability is defined over in-scope *cards*, not themes, so an empty card set fails the guard regardless of registry entries.
- **CloudKit sync timing**: scope changed on one device may arrive on another after a queue was already computed. Mitigation: the recompute trigger is idempotent and the helpers are deterministic, so a later recompute converges; first-run is gated locally to avoid sync-dependent onboarding.
- **Widening-then-narrowing churn**: repeatedly changing the level rewrites `selectedThemes`. Trade-off accepted: explicit, predictable persisted state is worth the extra writes, which are infrequent and user-initiated.
- **Guard UX**: blocking "deselect all" must be clearly communicated in Russian copy so the user understands why finishing is unavailable. Mitigation: keep at least one card-contributing theme implied as required in the UI.

## Open Questions

- Should lowering the level that drops previously selected themes warn the user before discarding them, or silently re-scope? (Default assumed: silent re-scope, since the dropped themes are no longer studyable.)
- Should settings expose the resulting in-scope card count as feedback? (Nice-to-have; not required by the spec.)
