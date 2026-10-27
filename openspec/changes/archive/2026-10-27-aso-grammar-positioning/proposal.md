## Why

The App Store page sells Lorito as «Испанский по карточкам» — a crowded,
generic promise that hides what makes the app different: a complete A1–C2
Spanish grammar explained in Russian through the mistakes Russian speakers
actually make. The audit names this as the most valuable advantage; the store
page is where it has to land first. The head search queries («испанский
язык», «учить испанский») and grammar terms (спряжение, subjuntivo) are
missing from the metadata, and Russian speakers living in Spain and Latin
America never see our Russian metadata because those storefronts do not index
the Russian localization.

## What Changes

- **Decision (owner):** Russian name «Lorito: испанский язык», subtitle
  «Грамматика по-русски, A1–C2».
- **Keywords** rebuilt around grammar intents, counted in characters (≤ 100);
  DELE/CCSE terms are added only in a second stage, once the exam path ships.
- **Description** rewritten: problem → what is inside → who it is for; in-app
  purchases disclosed once `lorito-pro` ships.
- **Cross-localization for the diaspora:** es-ES and es-MX localizations
  carrying Russian-language metadata aimed at Russian speakers, as a measured
  experiment with a review-risk note.
- **Screenshot plan** from the Plumaje screens (iPhone 6.9", iPad 13") with
  seeded demo data.
- **Metadata lint** and an **App Store Connect upload stage** through the
  existing fastlane lane and ASC API key.

## Capabilities

### New Capabilities
- `app-store-presence`: positioning, metadata fields and limits, staged
  keyword policy, cross-localization, IAP disclosure, screenshot set,
  validation and upload.

### Modified Capabilities
<!-- None. -->

## Impact

- `fastlane/metadata/ru/*.txt`; new `fastlane/metadata/es-ES/` and
  `fastlane/metadata/es-MX/` (Russian text).
- `ScreenshotUITests` scenes + seeded demo data; framing with headlines.
- New `tools/lint_metadata.py` (stdlib), run in CI before upload.
- Upload via the existing fastlane `submit`/`deliver` lane with the key in
  `secrets/asc.env`.
- No app code changes. Depends on `plumaje-design-system`,
  `recall-first-study` (archived); stage 2 depends on the exam-path change;
  the IAP disclosure depends on `lorito-pro`.
