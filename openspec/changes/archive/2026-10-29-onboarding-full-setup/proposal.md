## Why

After installing 2.0 the owner found the first run too thin: onboarding asks only for
the level, themes and a reminder, while the goal and exam, the Spanish variant, the
daily pace, the words and conjugation trainers and the sound settings are left to
post-session prompts or to Settings. Users who update from 1.5 never see the new
options at all, and there is no way to go through the setup again.

Owner decision (2026-10-29): onboarding sets up everything; users updating from an
earlier version go through it once; Settings can start it again, prefilled.

## What Changes

- Onboarding steps: level (or placement test) → themes → goal and exam → Spanish
  variant → pace (new cards, words, conjugations per day) → sound → reminders (last).
  The new steps can be skipped with the current values kept.
- Settings «Пройти настройку заново»: all steps, prefilled with the current values;
  no first-session start, progress untouched, skipping reminders keeps them as they are.
- A device that completed an earlier onboarding version goes through the new one once,
  prefilled (device-local version marker).
- Completing onboarding answers the post-session goal, variant and words prompts.
- New cards per day becomes editable (1–10), in onboarding and in Settings «Повторение».
- Analytics step names gain goal, variant, pace and sound.

## Capabilities

### Modified Capabilities
- `onboarding-and-selection`: step order, new steps, re-run, upgrade, card pace.
- `study-goal`: the goal is asked in onboarding; the prompt is only a fallback.
- `regional-variants`: the variant is asked in onboarding.

## Impact

- Features: `OnboardingView` (steps, mode first-run / revisit), `RootView` (version
  marker), Settings (re-run entry, card pace), `TodayModel` prompts.
- Domain: `OnboardingStepName`, onboarding version constant.
- No synced-store changes (the version marker is device-local), so no CloudKit schema change.
- Tests: Features (onboarding completion and revisit), UI tests for onboarding.
