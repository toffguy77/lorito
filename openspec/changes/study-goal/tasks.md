## 0. Dependencies

- [ ] 0.1 `learning-platform-foundation` applied (local learning day, `ItemKind`, new-introduction budget)
- [ ] 0.2 `cloudkit-schema-release` applied; `placement-test-and-first-session` applied (Today prompt slot)

## 1. Domain (TDD)

- [ ] 1.1 Write failing tests for pace: even split, round up, inclusive local learning days, only `.card` items, suspended and out-of-scope excluded, `max(pace, dailyNewCardCount)`, budget cap, determinism with injected today
- [ ] 1.2 Write failing tests for status: on track, behind by N, behind when the budget caps below pace
- [ ] 1.3 Write failing tests for lifecycle: level goal achieved / expired; exam achieved by date passing or done flag, not by cards; DELE A2 preset writes both parts
- [ ] 1.4 Implement `GoalPacing`, `ExamCountdown`; copy via `RussianPlural` (1 карточку / 2 карточки / 5 карточек; days)

## 2. Persistence

- [ ] 2.1 Add optional scalar fields `goalTargetLevel`, `goalTargetDate`, `goalStartDate`, `goalStartIntroduced`, `goalState`, `examKind`, `examDate`, `examDone` to the settings record; map both ways in `SwiftDataUserDataStore`
- [ ] 2.2 Store round-trip test; export dev schema to `cloudkit/schema.ckdb` per `cloudkit-schema-release`

## 3. Daily plan wiring

- [ ] 3.1 Write failing test: plan limit = max(pace, dailyNewCardCount) capped by budget while a level goal is active; `dailyNewCardCount` otherwise
- [ ] 3.2 Feed the limit in plan recomputation; composer untouched

## 4. Features

- [ ] 4.1 Settings → «Цель»: level goal, exam (DELE A2 / CCSE + date), preset "DELE A2", mark exam done, remove
- [ ] 4.2 Today goal card: learning days left, cards left, status with plurals; one-time end states
- [ ] 4.3 Post-first-session prompt «Есть дедлайн?» in the Today prompt slot; dismiss never returns

## 5. Validation

- [ ] 5.1 `swift test` green
- [ ] 5.2 `xcodebuild` build; UI test: finish first session → goal prompt → set DELE A2 → Today shows countdown; remove → card disappears
- [ ] 5.3 `openspec validate study-goal --strict`
