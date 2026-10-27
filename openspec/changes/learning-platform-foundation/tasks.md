## 1. Item kinds and card-only counts (Domain, TDD)

- [x] 1.1 Failing tests: `ItemKind.parse` for card / `conj:` / `word:` / `ccse:` / unknown ids
- [x] 1.2 Implement `ItemKind` in Domain
- [x] 1.3 Failing tests: `TodayModel`, `StatsCalculator` counts, `SessionSummary` and catalog statuses ignore non-card ids (fixtures with `conj:` events)
- [x] 1.4 Filter consumers to `.card`; planners skip `.unknown`

## 2. Local learning day (Domain, TDD)

- [x] 2.1 Failing tests: `LearningDay` buckets 22:00 in UTC−3 to the local date; due today uses the local date; DST transition day
- [x] 2.2 Replace the UTC calendars in `StatsCalculator`, `DueSelection`, `SpacedRepetitionScheduler`, `StudyGrade+Domain`, `DailyTrap` with `LearningDay` (time zone injected for tests)
- [x] 2.3 Re-run all Domain/Features tests; fix fixtures that assumed UTC

## 3. Introduction accounting and budget (Domain, TDD) — fixes the unlimited-new-cards bug

- [x] 3.1 Failing test reproducing the bug: limit 1 → grade the new card → recompose plan same day → no new card
- [x] 3.2 `IntroductionLedger(events:day:)` — earliest graded event per item; tests
- [x] 3.3 `DailyPlanner.selectNew` takes the remaining allowance (limit − introduced today)
- [x] 3.4 `DailyBudget` (default 10; order cards → conjugations → words → CCSE); tests for binding/non-binding budgets; conjugation/word quotas default 0
- [x] 3.5 `TodayModel` uses the ledger; UI test: finish the day's new card, return to Today → all-done, «Начать» unavailable

## 4. Memory update rule and in-session relearn

- [x] 4.1 Failing tests: `GradingService` updates `ReviewState` only for the first graded event of the learning day; later grades only append events
- [x] 4.2 Implement in `GradingService`; `ExercisePracticeService` goes through it
- [x] 4.3 `StudySessionModel`: append a card graded Опять once to the end of the queue (front side); tests: returns once, never twice, review state unchanged by the second grade
- [x] 4.4 Session progress counts the re-shown card as an extra step («5/13» → «6/14»)

## 5. Parser move (refactor, no behavior change)

- [x] 5.1 Move `CardBodyParser`, `CardBlock`, `CalloutKind` into Domain; update imports; keep `CardBodyParserTests` green (move them to DomainTests)

## 6. Spanish span interactions

- [x] 6.1 Spike: MarkdownUI theme renders Latin-letter emphasis as `lorito-es://span?text=…` links in the Spanish style, no underline; check long-press on links inside `Text`; record the result in design.md (fallback: a sheet listing the block's spans)
- [x] 6.2 `SpanishSpanActions` registry (features contribute menu items) + `OpenURLAction` handler; tap = primary action
- [x] 6.3 `SpanishText` uses the same contract; VoiceOver: speech language es, custom actions = menu items
- [x] 6.4 Tests: numbers/quotes stay plain; menu shows only registered items; tap is a no-op without audio

## 7. Validation

- [x] 7.1 `swift test` green; `xcodebuild` build; UI tests on iPhone 17 Pro
- [ ] 7.2 _(manual, on device — owner)_ Manual: change device time zone to America/Argentina/Buenos_Aires, study at 22:00 → counts for the local date
- [x] 7.3 `openspec validate learning-platform-foundation --strict`
