## 1. Metadata lint (TDD)

- [x] 1.1 Write failing tests (`tools/test_lint_metadata.py`): over-limit name/subtitle/promo/description, keywords > 100 characters, keyword ≤ 2 chars, duplicate keyword, keyword repeating a name/subtitle word, all localizations scanned
- [x] 1.2 Implement `tools/lint_metadata.py` (stdlib, character counts); add to CI before upload
- [x] 1.3 Run against current metadata and record findings (design/ASO.md: «A1», «B1» too short; description still said SM-2)

## 2. Russian copy (stage 1)

- [x] 2.1 Record the owner decision in metadata: name «Lorito: испанский язык», subtitle «Грамматика по-русски, A1–C2»
- [x] 2.2 Write promotional text and description per design structure; counts taken from `content.json` of the release build
- [x] 2.3 Write stage-1 keywords (design.md list, 90 chars); lint green
- [x] 2.4 Update `release_notes.txt`

## 3. Diaspora cross-localization

- [x] 3.1 Confirm which localizations the Spain, Mexico and Argentina storefronts index (aso.dev Spain row, Apple docs) — Spain: es-ES (+ca, en-GB); Mexico/Argentina: es-MX (+en-GB); Apple publishes no matrix (design/ASO.md)
- [x] 3.2 Create `fastlane/metadata/es-ES/` and `es-MX/` with Russian name, subtitle, keywords, description (first line: for Russian speakers learning Spanish); lint green
- [x] 3.3 Define the experiment readout: impressions and installs per storefront, 4 weeks

## 4. Screenshots

- [x] 4.1 Seeded demo store for UI tests (launch argument): reviews, streak, history, trap of the day
- [x] 4.2 Six scenes in `ScreenshotUITests` for iPhone 6.9" and iPad 13", light theme
- [ ] 4.3 Frame with Russian headlines (`tools/frame_screenshots.swift`, done); review at actual size on a phone — (manual, owner)

## 5. App Store Connect

- [ ] 5.1 (owner — needs explicit «да»: uploading to ASC) Upload metadata and screenshots via the existing fastlane `submit`/`deliver` lane with the API key from `secrets/asc.env`
- [ ] 5.2 (owner — confirm during the first upload) Make the lane fail on any rejected field; confirm from the response that a 90-character Cyrillic keyword string is accepted (character limit)
- [ ] 5.3 (owner) Verify the product page preview in App Store Connect for ru, es-ES, es-MX

## 6. Later stages

- [x] 6.1 Stage 2 (with exam path): switch to stage-2 keywords and add the exam paragraph; lint green
- [x] 6.2 With `lorito-pro`: add the free vs paid disclosure to every description

## 7. Validation

- [x] 7.1 `python3 tools/test_lint_metadata.py` and `python3 tools/lint_metadata.py` green
- [x] 7.2 Screenshot UI tests green on iPhone and iPad simulators
- [ ] 7.3 (owner, after release) After 4 weeks: compare impressions and conversion per storefront
- [x] 7.4 `openspec validate aso-grammar-positioning --strict`
