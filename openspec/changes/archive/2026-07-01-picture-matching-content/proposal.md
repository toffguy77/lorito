## Why

The `picture-matching` exercise type shipped with the practice-exercises engine, pipeline, and UI, but was deferred for content because it needs bundled image assets. This change enables it: a curated **OpenMoji** (CC BY-SA 4.0) vocabulary set plus real picture-matching exercises. It also fixes a bundle-resolution bug found while wiring the first asset — SwiftPM's `.process("Resources")` flattens resources, so images never resolved through `subdirectory:`.

## What Changes

- **Fix asset bundling**: split the Content target resources into `.process("Resources/content.json")` + `.copy("Resources/exercise-assets")` so the assets directory is preserved and `Bundle.module.url(…, subdirectory: "exercise-assets")` resolves. `compile.py` always creates the assets dir (`.gitkeep`) so `.copy` holds even with zero picture content.
- **Add image assets**: 32 OpenMoji everyday-vocabulary emojis (food, clothes, animals, household, nature), named by their Spanish word, bundled by the pipeline; `ATTRIBUTION.md` records the CC BY-SA 4.0 credit.
- **Author content**: 8 `picture-matching` exercises on card `A1-30` (Бытовая лексика). Bundle grows to 886 exercises / 32 assets.
- **Tests**: a Content test asserts every picture asset resolves via `Bundle.module`; a UI test drives to a real picture-matching exercise and confirms labels + images render on the simulator.

Content + a build-config fix; no Domain/Features source changes (the engine/UI already handled the type).

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `content-model`: Updates the "Exercise-type variety" requirement to note that `picture-matching` variety is now **enabled** (its image assets are bundled), rather than merely optional/pending.

## Impact

- **Content (added)**: `content/exercise-assets/*.png` (32 OpenMoji) + `ATTRIBUTION.md`; `content/A1/exercises/A1-EX-000.md` + `A1-EX-P01…P08.md`.
- **Build config (fixed)**: `Packages/LoritoKit/Package.swift` resources rule; `tools/compile.py` asset-dir handling.
- **Bundle (regenerated)**: `content.json` + `Resources/exercise-assets/`.
- **Tests (added)**: `ContentTests` asset resolution; `LoritoUITests` picture-matching render.
- **Licensing**: OpenMoji is CC BY-SA 4.0 — attribution must be shown in the app's credits/licenses (follow-up UI task).
- **No new third-party code dependencies.**
