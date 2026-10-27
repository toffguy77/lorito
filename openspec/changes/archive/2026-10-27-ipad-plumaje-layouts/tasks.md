## 0. Dependencies

- [x] 0.1 `plumaje-design-system`, `recall-first-study`, `progress-insights` applied

## 1. Navigation & state

- [x] 1.1 `AppNavigation` (`@Observable`): destination, catalog selection IDs, open session; owned above the size-class switch. Tests: resize/rotation keeps state (model-level)
- [x] 1.2 `AdaptiveRootView`: compact → existing tree; regular → iPad tree; reminder deep link routes through `AppNavigation`
- [x] 1.3 iPadOS 18: `TabView` + `.tabViewStyle(.sidebarAdaptable)`; iPadOS 17: `NavigationSplitView` + `Sidebar` (landscape) / `TopTabBar` (portrait). Same accessibility identifiers as the iPhone tab bar
- [x] 1.4 DesignSystem: `Sidebar` (with "Мой путь" level bars), `TopTabBar`, `KeyCap`, `KeyboardHintsPanel`; gallery entries

## 2. Screens at regular width

- [x] 2.1 Today: two-column dashboard (mockup `iPadToday.dc.html`)
- [x] 2.2 Session: centered front side; revealed two-column body via a `Layout` that assigns blocks to the shorter column, single column when it fits; side panel; grade row with key caps (mockup `iPadSession.dc.html`)
- [x] 2.3 Catalog: three-column `NavigationSplitView`, `@SceneStorage` selection (mockup `iPadCatalog.dc.html`)
- [x] 2.4 Progress: dashboard grid, larger heatmap cells (mockup `iPadProgress.dc.html`)
- [x] 2.5 Onboarding / Settings / Reminders: centered at reading width (no new layout)

## 3. Related cards (all devices, TDD)

- [x] 3.1 Failing tests: resolve `Card.related` against `ContentCatalog`, skip unknown, keep order
- [x] 3.2 Show after reveal: iPhone — section at the end of the card; iPad — side panel; tap opens reader sheet, session continues

## 4. Input

- [x] 4.1 `.keyboardShortcut`: Return (start), Space (reveal), 1–4 (grades), Esc (close); bound to the visible buttons only (E / ⌘F dropped — no such actions yet)
- [x] 4.2 Arrow-key navigation in catalog lists (native `List` selection)
- [x] 4.3 `.hoverEffect` on interactive components (tab items, rows, buttons, chips)

## 5. Validation

- [x] 5.1 UI tests on iPad 13" simulator: sidebar navigation; keyboard-only session (Return → Space → 3); pressing 3 before reveal does nothing; catalog selection survives rotation (`XCUIDevice.shared.orientation`) _(Return/Esc can't be synthesized by XCUITest on the simulator — test falls back to a tap; verify on device)_
- [ ] 5.2 _(manual, on device — handed to the owner)_ Manual: Split View / Stage Manager resize mid-session; Slide Over shows iPhone layout; pointer hover; ⌘ overlay lists shortcuts
- [x] 5.3 `swift test` green; existing iPhone UI tests unchanged
- [x] 5.4 fastlane: add iPad 13" landscape screenshots (Today, Session, Catalog, Progress)
- [x] 5.5 `openspec validate ipad-plumaje-layouts --strict`
