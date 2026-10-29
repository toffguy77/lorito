## 1. Domain and models

- [x] 1.1 Failing tests: onboarding completion (first run and revisit) answers the goal, variant and words prompts; revisit grants no first-session boost and keeps reviews; card pace clamps to 1–10
- [x] 1.2 `OnboardingStepName` gains goal, variant, pace, sound; `Onboarding.currentVersion` and a device-local completed-version store
- [x] 1.3 `OnboardingSetupModel`: card pace, words and conjugation quotas, variant, speech rate and silent playback (load fresh, save per step)

## 2. Views

- [x] 2.1 `OnboardingView` mode first-run / revisit; steps goal (reuses the goal settings), variant, pace, sound; progress of 7 steps; «Пропустить» on the new steps; close in revisit
- [x] 2.2 `RootView`: show onboarding when the completed version on this device is older than current (prefilled, no session start)
- [x] 2.3 Settings: «Пройти настройку заново» (full-screen) and «Новых карточек в день» in «Повторение»

## 3. Tests and verify

- [x] 3.1 UI tests: first run walks all steps; Settings re-run opens prefilled and closes; existing onboarding helpers updated
- [x] 3.2 `swift test`; UI suite on iPhone and iPad; `openspec validate onboarding-full-setup --strict`
