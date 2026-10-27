## 0. Dependencies

- [ ] 0.1 `plumaje-design-system` applied; `recall-first-study` applied (`DailyTrap` → word of the day)

## 1. Project & signing

- [ ] 1.1 `project.yml`: add `LoritoWidgets` (`type: app-extension`, WidgetKit/ActivityKit, depends on LoritoKit `Domain` + `DesignSystem`), embed in `Lorito`
- [ ] 1.2 App Group `group.com.toffguy.lorito` in both entitlements; `NSSupportsLiveActivities: YES` in app Info.plist
- [ ] 1.3 Register App Group + extension App ID in the developer portal; update fastlane signing; `xcodegen generate` and build

## 2. Snapshot (Domain + Features, TDD)

- [ ] 2.1 Failing tests: `WidgetSnapshot.make(...)` pure builder — counts, streak, studied-today, ≤ 3 questions from multiple-choice exercises in scope, deterministic for identical inputs; Codable round-trip with `version: 1`
- [ ] 2.2 `WidgetSnapshotWriter`: atomic write to the App Group container; `WidgetCenter.reloadAllTimelines()`; hook into launch / foreground / day rollover / session completion (same places as reminder reschedule)
- [ ] 2.3 Test with a temp directory that the file is written and replaced atomically

## 3. Widgets

- [ ] 3.1 `TimelineProvider` reading the snapshot; entries now + next local midnight; neutral state for missing/unknown version
- [ ] 3.2 Small "Серия", small "Слово дня", Lock Screen circular + rectangular (mockup `Widgets.dc.html`); deep link `lorito://today`
- [ ] 3.3 Medium "Вспомни": `AnswerQuestionIntent` stores the choice in App Group defaults, shows correct/incorrect, "Дальше"; assert no store writes
- [ ] 3.4 Register fonts in the extension; verify fallbacks

## 4. Live Activity & share

- [ ] 4.1 `SessionActivityController` start/update/end; minutes-left estimate; single active activity
- [ ] 4.2 Dynamic Island compact/expanded + Lock Screen presentation (mockup)
- [ ] 4.3 `StreakShareCard` + `ImageRenderer` + `ShareLink` on the completion state

## 5. Validation

- [ ] 5.1 `swift test` green; extension builds for device
- [ ] 5.2 Manual on device: widgets in light/dark/tinted, Lock Screen, StandBy; Live Activity through a full session; share sheet image
- [ ] 5.3 `openspec validate home-screen-widgets --strict`
