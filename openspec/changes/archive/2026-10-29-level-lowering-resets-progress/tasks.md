## 1. Model

- [x] 1.1 Failing tests: `ScopeSelectionModel` counts cards with progress above a level; persisting a lower level deletes only those card reviews (words, conjugations, lower cards, study log kept); raising or keeping the level deletes nothing
- [x] 1.2 Implement `cardsWithProgress(above:)` and the reset in `persist`

## 2. UI

- [x] 2.1 Settings level chips: confirmation dialog with the card count before a lowering that resets progress; cancel keeps the level
- [x] 2.2 Onboarding level step «Далее»: the same confirmation against the stored level
- [x] 2.3 UI test: study B1 cards, lower to A1 in Settings, confirm, the next session has no B1 card

## 3. Verify

- [x] 3.1 `swift test`; UI on iPhone and iPad (new test plus onboarding, placement and setup tests; full suite not rerun); `openspec validate level-lowering-resets-progress --strict`
