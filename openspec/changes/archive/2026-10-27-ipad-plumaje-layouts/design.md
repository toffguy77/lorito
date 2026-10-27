## Context

Current iPad behavior (spec `ipad-support`): universal binary, all orientations,
`LoritoLayout.readingWidth = 640` caps cards, otherwise iPhone layouts. Root
navigation is a `TabView` in `MainTabView` with a reminder deep link to Today.
Deployment target is iOS 17. Mockups: `design/mockups/iPadToday.dc.html`,
`iPadSession.dc.html`, `iPadCatalog.dc.html`, `iPadProgress.dc.html`
(canvas row "iPad").

## Goals / Non-Goals

**Goals:** native-feeling iPad layouts at regular width; full keyboard
operation of the study loop; seamless size-class transitions; no feature
divergence between devices.

**Non-Goals:** Mac Catalyst / "Designed for iPad" on Mac tuning; Apple Pencil
features beyond the system Scribble that `TextField` already provides;
drag-and-drop matching exercises; multiple windows (`UIApplicationSupportsMultipleScenes`
stays false); landscape on iPhone.

## Decisions

**Layout by horizontal size class, not by device.** `AdaptiveRootView` reads
`horizontalSizeClass`: `.compact` → current iPhone tree (floating bottom bar);
`.regular` → iPad tree. iPad in Slide Over or narrow Split View is compact and
gets the iPhone layout automatically. Navigation state (selected destination,
catalog selection, open session) lives in one `@Observable AppNavigation`
owned above the switch so a resize never resets it.

**Sidebar vs top tab bar.** On iPadOS 18+ use `TabView` with
`.tabViewStyle(.sidebarAdaptable)` — the system shows a top tab bar that the
user can expand into a sidebar, and handles the portrait/landscape default.
On iPadOS 17 fall back to `NavigationSplitView` with a custom `Sidebar`
(landscape) and the custom `TopTabBar` (portrait). Both render the same four
destinations with the same identifiers, so UI tests are shared.

**Catalog = `NavigationSplitView` with three columns.** Column 1 levels/themes,
column 2 cards (status chips), detail = card reader. Selections are
`@SceneStorage`-backed IDs so rotation and relaunch restore them. In compact
width the same view collapses into the existing push navigation.

**Session at regular width.** The card container splits the revealed body:
left column renders the recall prompt's answer zone and leading Markdown
blocks; right column renders the Суть callout, tables and mistakes. Split rule:
blocks are assigned in order to the shorter column (measured with
`Layout`), callouts stay whole. Each column respects `readingWidth / 2 + gutter`
so the existing reading-width requirement still holds. Side panel (300 pt):
related cards + keyboard hints. Grade bar spans the card width with key caps.

**Keyboard.** SwiftUI `.keyboardShortcut` on buttons (shows in the ⌘ overlay):
Space → "Показать ответ", 1/2/3/4 → grades. Return → "Начать" (Today) and
Esc → close session go through a UIKit `UIKeyCommand` with
`wantsPriorityOverSystemBehavior` (the iPadOS focus system otherwise consumes
them; SwiftUI can't set that flag), also listed in the ⌘ overlay. Arrow keys in
catalog lists via `List` selection (native). "E → expand card" and "⌘F →
catalog search" were dropped: neither action exists in the app; they belong to
a future change that adds them. Shortcuts are active only when
the corresponding button is visible and enabled, so they cannot grade a card
before reveal.

**Related cards.** `Card.related` IDs resolved via `ContentCatalog`; unknown
IDs are skipped. Shown after reveal only (they would leak the answer
otherwise). Tapping opens the card reader as a sheet without ending the
session.

## Risks / Trade-offs

- [Two layout trees diverge over time] → shared subviews (hero, card blocks,
  grade bar) with layout-only wrappers; one UI test suite run on both iPhone
  and iPad simulators.
- [`sidebarAdaptable` unavailable on iOS 17] → explicit fallback; drop it when
  the deployment target moves to 18.
- [Column-splitting a card reads oddly for short cards] → if total height fits
  one column, render single column centered.
- [Space bar conflicts with VoiceOver / text fields] → shortcut attached only
  to the reveal button; no text fields in the session.

## Migration Plan

Layout-only; ship together with or after `plumaje-design-system`. Rollback:
revert to the compact tree for all size classes (one switch in
`AdaptiveRootView`).
