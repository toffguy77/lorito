# App Store presence (aso-grammar-positioning)

Positioning: Spanish grammar explained in Russian, A1–C2. Metadata lives in
`fastlane/metadata/<locale>/`; `tools/lint_metadata.py` checks it (the
`ci_release` / `submit` lanes run it before upload, with the exam terms
forbidden until stage 2).

## Lint findings on the 2.0 metadata (before this change)

`python3 tools/lint_metadata.py` on the Plumaje 2.0 metadata failed:

- `ru/keywords.txt`: «A1» and «B1» are too short (Apple ignores keywords of two
  characters or fewer).

Also not caught by the lint, but out of date: the 2.0 description said
"Интервальное повторение (SM-2)"; since `fsrs-scheduler` the scheduler is
FSRS. The stage-1 copy replaces both.

## Stage 1 (this release)

| Field | ru / es-ES / es-MX | Characters |
|---|---|---|
| Name | Lorito: испанский язык | 22 |
| Subtitle | Грамматика по-русски, A1–C2 | 27 |
| Keywords | испанская,учить,правила,глаголы,спряжение,времена,субхунтив,subjuntivo,карточки,упражнения | 90 (161 bytes) |
| Promotional text | see `promotional_text.txt` | 153 |

Counts in the description come from the compiled `content.json`: 159 cards,
30 themes, 6 levels, 937 exercises, 100 verbs in 14 tenses, 2843 words in 58
decks, 3 DELE A2 mocks, 300 CCSE questions (2.0). Re-check them whenever content changes.

Stage 2 (with the exam path) swaps in the stage-2 keywords from the change's
design.md, adds the exam paragraph and removes `METADATA_FORBIDDEN_TERMS` from
the Fastfile.

## Diaspora cross-localization

Storefront → indexed localizations (aso.dev cross-localization table,
checked 2026-10-27; Apple publishes no official matrix):

| Storefront | Primary | Additional |
|---|---|---|
| Russia | ru | en-GB, uk |
| Spain | es-ES | ca, en-GB |
| Mexico | es-MX | en-GB |
| Argentina | es-MX | en-GB |

So es-ES reaches Spain and es-MX reaches Mexico and Argentina. Both carry the
Russian metadata. The first line of each description says the app is for
Russian speakers learning Spanish. Risk: App Review may question Russian text
in a Spanish localization. If it is rejected, delete the two directories and
re-upload.

## Experiment readout (4 weeks after release)

Source: App Store Connect → Analytics → Acquisition, filtered by territory.

- **Storefronts:** Spain, Mexico, Argentina. Control: Russia.
- **Metrics per storefront and per week:** impressions (search), product page
  views, first-time downloads, conversion rate (downloads ÷ impressions).
- **Baseline:** the 4 weeks before the stage-1 release.
- **Success:** Spain, Mexico or Argentina search impressions rise clearly
  above baseline (at least ×2 from a small base). Downloads must rise along
  with them, while Russia stays roughly flat.
- **Decision:**
  - keep the cross-localizations if they succeed;
  - remove the ones that add no impressions after 4 weeks;
  - revert immediately on an App Review rejection.

## Screenshots

`ScreenshotUITests` launches with `-lorito-demo-data`, which seeds the
in-memory store with `DemoSeed`: a 12-day streak, 12 weeks of history, A1 in
long-term memory, reviews due today, a DELE A2 date and the conjugation and
words trainers. Since 2.0 it captures eight scenes per device: Today, «Частые
ошибки», DELE A2 track, conjugation trainer, exercise, Spanish variant (setup
re-run), recall front, progress.

`fastlane snapshot` writes raw captures to `fastlane/screenshots_raw/`.
`swift tools/frame_screenshots.swift` adds the headlines from
`fastlane/screenshot_headlines.json` and writes the results to
`fastlane/screenshots/{ru,es-ES,es-MX}`. Review the framed images at actual
size on a phone before upload.

## Marketing surfaces (2.0)

Copy for the creative assets, custom product pages, the in-app event and the
featuring nomination is in `fastlane/marketing/copy.json`; media in
`fastlane/marketing/media/`:

- `tools/render_marketing.sh [captures]` renders the header, search results,
  event and featuring art from `design/marketing/`.
- `tools/record_app_preview.sh <udid> iphone|ipad` records the app previews.

Custom product page keywords must come from the keyword field and be unique to
one page; they are assigned in App Store Connect (web).

API scripts (env from `secrets/asc.env`): `tools/upload_app_previews.rb <version>`,
`tools/create_app_event.rb <start> <days>`, `tools/create_custom_product_pages.rb`,
`tools/create_nomination.rb <publish-start> [--draft]`.

2.0 release: scheduled for 2026-11-24 10:00 MSK (repository variable
`LORITO_RELEASE_AT`, read by `ci_release`), matching the featuring nomination
submitted earlier from `release/2.0-plumaje/`; the in-app event runs
2026-11-24 → 2026-12-08.
