## Context

Picture-matching shipped using OpenMoji (CC BY-SA 4.0) images. That license mandates attribution in the distributed product; without an in-app credits surface the assets can't ship. The app's `SettingsView` already uses a `NavigationLink` pattern (e.g. «Напоминания»), so an About entry fits naturally.

## Goals / Non-Goals

**Goals:** a simple, static About/Licenses screen listing third-party credits (OpenMoji, MarkdownUI) reachable from Settings; expand the A1 picture-matching vocabulary to its practical max; all tests green and screen verified on the simulator.

**Non-Goals:** a full "settings/about" redesign; dynamic/remote license data; localizing license texts (Russian labels, license names/URLs as-is); picture-matching beyond A1 vocabulary.

## Decisions

### Static in-app license list
Model each entry as a small value type `LicenseEntry(name, license, detail, url)` and render a plain SwiftUI list. **Why:** licenses are known at build time; a static list is simplest, testable, and offline. The list is the single source of truth and is easy to extend when dependencies change.

### Credits included
- **OpenMoji** — CC BY-SA 4.0 — the required attribution ("All emojis designed by OpenMoji — the open-source emoji and icon project. License: CC BY-SA 4.0"), source https://openmoji.org.
- **MarkdownUI** — MIT — the one third-party Swift package (renders card bodies).

### Reachable from Settings
Add a «О приложении» `NavigationLink` in `SettingsView` (same style as «Напоминания») → `AboutView`. Keeps discovery obvious without new navigation infrastructure.

### Picture-matching expansion
Add ~25 more OpenMoji everyday nouns (family, body, animals, food) named by their Spanish word, and 6 more A1-30 `picture-matching` exercises (14 total). Grounded in A1-30 (Бытовая лексика); 4–5 label↔image options each; auto-checked.

## Risks / Trade-offs

- **Attribution wording must satisfy CC BY-SA** → use OpenMoji's recommended credit line verbatim; keep the source URL visible.
- **License list drifting from actual dependencies** → a Features test asserts the list is non-empty and includes OpenMoji; extend the list when `Package.swift` dependencies change (documented in the view).
- **Bundle size** → ~57 small PNGs total ≈ 230 KB; negligible.

## Migration Plan

Implement `AboutView` + `LicenseEntry`; wire the Settings entry; add assets + exercises; recompile; `swift test`; build + UI test/screenshot on the simulator. Additive and reversible.

## Open Questions

- Whether to also show app version / build — cheap to add later; out of scope now.
