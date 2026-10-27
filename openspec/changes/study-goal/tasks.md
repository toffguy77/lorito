## 1. Domain (TDD)

- [ ] 1.1 Write failing tests: `StudyGoal` Codable round-trip; `UserSettings` decodes old payloads without `goal` as nil
- [ ] 1.2 Write failing tests for `GoalPacing.pace`: even split, rounding up, min 1, max 10, inclusive day count, suspended and out-of-scope cards excluded, determinism with injected today
- [ ] 1.3 Write failing tests for `GoalPacing.status`: on track, behind by N, behind when clamped at max
- [ ] 1.4 Write failing tests for lifecycle: achieved, expired, active; achieved/expired produce no pace
- [ ] 1.5 Implement `StudyGoal`, `GoalConstants`, `GoalPacing`

## 2. Daily plan wiring

- [ ] 2.1 Write failing test: the plan uses the goal pace as the new-card limit while a goal is active, `dailyNewCardCount` otherwise
- [ ] 2.2 Feed the limit in `TodayModel` / plan recomputation; composer untouched

## 3. Features

- [ ] 3.1 Settings → "Цель": presets ("Закрыть уровень", "DELE A2"), custom level + date picker (future dates only), remove goal
- [ ] 3.2 Today goal card: days left, cards left, "в графике" / "отстаёте на N карточек"; one-time end state for achieved / expired
- [ ] 3.3 Onboarding: optional goal step after themes, before the reminder step; skip leaves no goal
- [ ] 3.4 Persist via `UserSettings.goal`; verify sync round-trip with the existing store tests

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test: set a goal in Settings → Today shows the countdown; remove goal → card disappears
- [ ] 4.3 `openspec validate study-goal --strict`
