## Why

The owner started on B1, studied a session, then lowered the level to A1 in Settings,
and kept getting B1 cards: lowering the level only narrows new cards, while every card
already started keeps coming back for review.

Owner decision (2026-10-29): lowering the target level resets the progress of the cards
above the new level.

## What Changes

- Persisting a lower target level (Settings or the onboarding re-run) deletes the review
  state of every grammar card above the new level; those cards become new again and
  return only when the level is raised. The study log, words, conjugations and CCSE
  items are untouched.
- Before a lowering that would reset progress, the app asks for confirmation, naming how
  many cards lose progress; cancelling keeps the current level.
- The re-run requirement keeps progress except for this reset.

## Capabilities

### Modified Capabilities
- `onboarding-and-selection`: lowering the level resets progress above it, with confirmation.

## Impact

- `ScopeSelectionModel` (count and reset on persist), `SettingsView` and `OnboardingView`
  (confirmation). Review records are deleted through the existing `deleteReview`; no
  schema change.
