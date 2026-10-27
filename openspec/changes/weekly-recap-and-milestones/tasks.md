## 0. Dependencies

- [ ] 0.1 `progress-insights` applied (long-term memory by level, daily activity series)
- [ ] 0.2 Optional: `personal-traps` applied (top trap source); otherwise use the Опять fallback

## 1. Domain (TDD)

- [ ] 1.1 Write failing tests for `WeeklyRecap.make`: week ending on the latest Sunday; days studied; new rules (first study event in week); current long-term count; top trap and fallback; empty week; determinism with injected today
- [ ] 1.2 Write failing tests for `LevelMilestones.newlyClosed`: closed when all non-suspended cards are long-term; only included levels; excludes celebrated levels
- [ ] 1.3 Implement both, reusing the stats calculator's week boundary and the long-term rule

## 2. Persistence

- [ ] 2.1 `UserSettings.lastRecapWeek: String?` and `celebratedLevels: [CEFRLevel]` with defaults; decode old payloads; store round-trip test

## 3. Features

- [ ] 3.1 Today recap card: once per week from Sunday, dismiss records the week; encouraging empty state
- [ ] 3.2 Milestone celebration sheet "A1 закрыт" with share action; records the level as celebrated
- [ ] 3.3 Share images (9:16, `ImageRenderer`, `ShareLink`): recap and certificate; content limited to brand mark, numbers/level, month and year; copy "уровень пройден в Lorito"
- [ ] 3.4 Tests: share image view model contains no user name or identifiers

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test with seeded data: recap appears on Sunday once; milestone celebration appears once for a closed level
- [ ] 4.3 `openspec validate weekly-recap-and-milestones --strict`
