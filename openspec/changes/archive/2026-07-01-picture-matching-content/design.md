## Context

`practice-exercises` (all phases) shipped the six-type engine, including `picture-matching` (Domain checking, pipeline asset validation/bundling, and an AsyncImage-based UI). Content was deferred because no image assets existed. This change delivers the assets + content and fixes the one integration gap discovered when the first real asset was wired.

## Goals / Non-Goals

**Goals:** enable `picture-matching` end-to-end with real, licensed images; fix the bundle-resolution bug; author a solid A1 vocabulary set; verify on the simulator.

**Non-Goals:** an in-app licenses/credits screen (follow-up); picture-matching beyond A1 vocabulary; changing the engine/UI (already built).

## Decisions

### `.copy` for the assets directory (the fix)
SwiftPM `.process("Resources")` flattens/relocates resources, so `Bundle.module.url(forResource:withExtension:subdirectory:"exercise-assets")` returned nil. Splitting into `.process("Resources/content.json")` + `.copy("Resources/exercise-assets")` preserves the directory verbatim, so the subdirectory lookup resolves. `compile.py` always creates the dir (with `.gitkeep`) so the `.copy` rule never points at a missing path when there are zero picture exercises. **This was caught by a Content test before authoring any bulk content** — the smoke-test-first approach paid off.

### OpenMoji as the asset source
OpenMoji (CC BY-SA 4.0) gives a consistent, openly-licensed emoji set covering everyday A1 vocabulary. Assets are unmodified 72×72 color PNGs named by the Spanish word (`perro.png`, `cafe.png`), fetched via a jsdelivr GitHub mirror. Attribution is recorded in `content/exercise-assets/ATTRIBUTION.md`; the app must surface it in credits (follow-up). Filenames are ASCII (`cafe`, `pantalon`); the exercise `label` carries the accented Spanish (`café`, `pantalón`).

### Content scoped to A1-30 (Бытовая лексика)
Concrete-noun picture-matching fits the everyday-vocabulary card. Eight exercises group related items (food ×2, clothes, animals, household, nature, mixed), 4 label↔image options each.

## Risks / Trade-offs

- **Licensing** → OpenMoji CC BY-SA 4.0 requires attribution + share-alike; recorded in ATTRIBUTION.md; must appear in app credits before release (flagged).
- **Bundle size** → 32 PNGs ≈ 130 KB; negligible.
- **Asset-resolution regressions** → guarded by the Content test (`Bundle.module` resolution) and the UI render test; both run in CI-able suites.

## Migration Plan

Assets → `content/exercise-assets/`; author exercises; `validate.py` (asset existence) → `compile.py` (copies + counts assets) → `swift test` → simulator UI test/screenshot. Additive and reversible.

## Open Questions

- In-app licenses/credits screen for OpenMoji attribution — separate UI follow-up.
- Extending picture-matching to more vocabulary/levels — future content change.
