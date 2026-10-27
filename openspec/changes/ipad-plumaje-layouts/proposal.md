## Why

`ipad-support` made Lorito a correct universal app: it installs, rotates and
caps the reading width. On a 13" screen it is still an enlarged iPhone — a
bottom tab bar, one narrow column and acres of empty space, no keyboard
support. iPad is where people study at a desk with a Magic Keyboard, and it is
the device App Review editors and design juries look at first. With the
Plumaje redesign landing, iPad should get layouts built for it.

## What Changes

- **Adaptive navigation:** at regular width a sidebar (iPadOS 18
  `sidebarAdaptable` tab view; iPadOS 17 `NavigationSplitView` sidebar) with
  the four destinations and a "Мой путь" level summary; in portrait a floating
  top tab bar; compact width keeps the iPhone floating bottom bar.
- **Today dashboard (regular width):** two columns — plan hero with start
  action on the left; week strip, trap of the day and long-term memory on the
  right.
- **Study session (regular width):** the revealed card uses two columns
  (examples + rule / essence + table + mistakes), a side panel with related
  cards and keyboard hints, and a full-width grade bar with key caps.
- **Catalog (regular width):** three columns — levels and themes, the theme's
  cards with status, and the card reader — with selection kept across
  rotation and size changes.
- **Progress (regular width):** dashboard grid with larger heatmap cells and
  per-level memory bars.
- **Hardware keyboard:** Return starts the session, Space reveals the answer,
  1–4 grade, E expands the card, Esc closes, ⌘F searches the catalog, arrow
  keys move through catalog lists; all discoverable in the ⌘ overlay.
- **Pointer and multitasking:** hover effects on interactive elements; Split
  View / Stage Manager resizes switch between compact and regular layouts
  without losing navigation or session state.
- **Related cards** (all devices): a revealed card lists its `related` cards;
  on iPhone as a section at the end of the card, on iPad in the side panel.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `ipad-support`: screens gain regular-width layouts, adaptive navigation,
  keyboard shortcuts, pointer hover and size-class transitions; the
  "behavior identical" rule is clarified to allow layout and input differences
  but no feature differences.
- `study-flow`: revealed cards show related cards.

## Impact

- **Features**: `MainTabView` → `AdaptiveRootView` (size-class switch),
  regular-width variants of `TodayView`, `StudySessionView`, `CatalogView`,
  `StatsView`; `.keyboardShortcut` / `.onKeyPress` handlers; `.hoverEffect`.
- **DesignSystem**: `Sidebar`, `TopTabBar`, `KeyCap`, `KeyboardHintsPanel`
  components; `LoritoLayout` breakpoints.
- **Domain**: none (layout-only, plus reading `Card.related`, already present).
- **Tests/screenshots**: iPad UI tests for each layout; fastlane iPad 13"
  screenshots in landscape.
- Depends on `plumaje-design-system`, `recall-first-study` (reveal step) and
  `progress-insights` (week strip, memory, heatmap).
