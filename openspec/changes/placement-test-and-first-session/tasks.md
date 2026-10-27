## 1. Domain: placement algorithm (TDD)

- [ ] 1.1 Write failing tests for question selection: starts at A2; two correct → up; wrong → down; only multiple-choice / picture-matching / word-order; no exercise repeated; prefers an unasked theme at a level
- [ ] 1.2 Write failing tests for the stopping rule (12-question budget; passed level + failed level above) and the proposed level (worked examples from the spec; A1 fallback)
- [ ] 1.3 Write failing tests: determinism for identical pool + seed + history; scripted replay of a full session
- [ ] 1.4 Implement `PlacementTest` (pure, constants in Domain) until tests pass

## 2. Domain: traps from failures (TDD)

- [ ] 2.1 Write failing tests: first «Частые ошибки» item per failed card via `CardBodyParser`, dedupe by card, max 3, most recent first, cards without mistakes skipped
- [ ] 2.2 Implement `PlacementTest.traps(...)`

## 3. Features: onboarding

- [ ] 3.1 `OnboardingView` level step: "Не знаю — проверить за 2 минуты" action (mockup `Onboarding.dc.html`)
- [ ] 3.2 Placement flow screen reusing the exercise input components (focus-mode surfaces), progress indicator, close returns to manual list
- [ ] 3.3 Result screen: proposed level pre-selected, "ваши 3 ловушки", accept / choose another; applies the level through `ScopeSelectionModel.selectLevel`
- [ ] 3.4 Test: completing the placement test writes no `CardReview`, study event or `ExerciseAttempt` (fake store)

## 4. Features: first session hand-off

- [ ] 4.1 Transient `startFirstSession` flag set on onboarding completion; consumed once by the main flow
- [ ] 4.2 Present the study session when the queue is non-empty; otherwise Today; never on relaunch
- [ ] 4.3 Keep the pending `streak-reminders` reminder step as the final onboarding step before the hand-off

## 5. Validation

- [ ] 5.1 `swift test` green
- [ ] 5.2 `xcodebuild` build; UI test: fresh install → "Не знаю" → answer scripted questions → accept level → session opens on the first card's front side
- [ ] 5.3 UI test: manual level path still completes onboarding; relaunch lands on Today
- [ ] 5.4 `openspec validate placement-test-and-first-session --strict`
