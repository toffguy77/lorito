# Tasks

Enable `picture-matching` end-to-end with an OpenMoji vocabulary set.
(Delivered and verified on the simulator; recorded here for the OpenSpec history.)

## 1. Fix asset bundling
- [x] 1.1 Split Content target resources: `.process("Resources/content.json")` + `.copy("Resources/exercise-assets")` so images resolve via `subdirectory:`
- [x] 1.2 `compile.py` always creates the assets dir (+`.gitkeep`) so `.copy` holds with zero picture content
- [x] 1.3 Content test asserts every picture asset resolves via `Bundle.module`

## 2. Image assets
- [x] 2.1 Curate ~32 OpenMoji (CC BY-SA 4.0) everyday-vocabulary emojis, named by Spanish word, into `content/exercise-assets/`
- [x] 2.2 Add `content/exercise-assets/ATTRIBUTION.md` (OpenMoji CC BY-SA 4.0 credit)

## 3. Content
- [x] 3.1 Author 8 `picture-matching` exercises on card A1-30 (food, clothes, animals, household, nature, mixed)
- [x] 3.2 Run `tools/validate.py` (asset existence) and `tools/compile.py` (assets copied + counted)

## 4. Verify
- [x] 4.1 Run `swift test` (green; asset resolution test passes)
- [x] 4.2 Build the app and run `PracticeFlowUITests.testPictureMatchingRenders` on the simulator; confirm labels + images render (screenshot captured)
- [x] 4.3 Run `openspec validate picture-matching-content --strict`
