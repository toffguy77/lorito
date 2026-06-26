## 1. Domain stats calculator (pure, TDD)

- [ ] 1.1 Define the result value type: `currentStreak`, `bestStreak`, `studiedToday`, `studiedThisWeek`, `studiedAllTime`
- [ ] 1.2 Write failing tests: studied-today streak; not-today-but-yesterday streak; gap resets to 0; no-history → 0; best streak from history; counts (today/week/all-time); determinism with injected today
- [ ] 1.3 Implement `StatsCalculator` over `[StudyEvent]` + injected today using the app's shared day calendar; no I/O, no ambient clock
- [ ] 1.4 Confirm the calculator and its types import nothing from SwiftUI/SwiftData/CloudKit

## 2. Progress screen (Features)

- [ ] 2.1 Add a view-model that loads `allEvents()` from the store and runs `StatsCalculator` with `Date()` as today
- [ ] 2.2 Build the progress screen: prominent current streak, best streak, and today/this-week/all-time counts using design-system tokens
- [ ] 2.3 Implement the empty/zero state for no history
- [ ] 2.4 Recompute on appearance so it reflects sessions completed since last shown

## 3. Navigation

- [ ] 3.1 Wire the progress screen as a top-level destination (tab) alongside Today, Catalog, Settings
- [ ] 3.2 Confirm it consumes only foundation contracts (StudyLog, UserDataStore, DesignSystem) and the pure calculator

## 4. Validation

- [ ] 4.1 Run the full test suite incl. the new calculator tests; confirm green
- [ ] 4.2 Build the app and verify the screen renders with and without history
- [ ] 4.3 Run `openspec validate stats-and-streak --strict` and fix until valid
