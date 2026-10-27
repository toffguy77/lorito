## 0. Dependencies

- [x] 0.1 `plumaje-design-system` applied; `recall-first-study` applied (`DailyTrap` → word of the day)

## 1. Project & signing

- [x] 1.1 `project.yml`: add `LoritoWidgets` (`type: app-extension`, WidgetKit/ActivityKit, depends on LoritoKit `Domain` + `DesignSystem`), embed in `Lorito`
- [x] 1.2 App Group `group.com.toffguy.lorito` in both entitlements; `NSSupportsLiveActivities: YES` in app Info.plist
- [ ] 1.3 _(owner: Developer Portal + signing — steps in the implementation report)_ Register App Group + extension App ID in the developer portal; update fastlane signing; `xcodegen generate` and build

## 2. Snapshot (Domain + Features, TDD)

- [x] 2.1 Failing tests: `WidgetSnapshot.make(...)` pure builder — counts, streak, studied-today, ≤ 3 questions from multiple-choice exercises in scope, deterministic for identical inputs; Codable round-trip with `version: 1`
- [x] 2.2 `WidgetSnapshotWriter`: atomic write to the App Group container; `WidgetCenter.reloadAllTimelines()`; hook into launch / foreground / day rollover / session completion (same places as reminder reschedule)
- [x] 2.3 Test with a temp directory that the file is written and replaced atomically

## 3. Widgets

- [x] 3.1 `TimelineProvider` reading the snapshot; entries now + next local midnight; neutral state for missing/unknown version
- [x] 3.2 Small "Серия", small "Слово дня", Lock Screen circular + rectangular (mockup `Widgets.dc.html`); deep link `lorito://today`
- [x] 3.3 Medium "Вспомни": `AnswerQuestionIntent` stores the choice in App Group defaults, shows correct/incorrect, "Дальше"; assert no store writes
- [x] 3.4 Register fonts in the extension; verify fallbacks

## 4. Live Activity & share

- [x] 4.1 `SessionActivityController` start/update/end; minutes-left estimate; single active activity
- [x] 4.2 Dynamic Island compact/expanded + Lock Screen presentation (mockup)
- [x] 4.3 `StreakShareCard` + `ImageRenderer` + `ShareLink` on the completion state

## 5. Validation

- [x] 5.1 `swift test` green; extension builds for device _(unsigned device compile; signed build after 1.3)_
- [ ] 5.2 _(manual, on device — handed to the owner)_ Manual on device: widgets in light/dark/tinted, Lock Screen, StandBy; Live Activity through a full session; share sheet image
- [x] 5.3 `openspec validate home-screen-widgets --strict`
