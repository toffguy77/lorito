## Why

The owner's review of the approved 2.0 store media (2026-11-02) found defects that buyers see.
The progress screenshot shows the «Учиться вместе» iCloud-required error. The same capture is
used on two custom product pages and on the in-app event art. Two tiles on the same screen
contradict each other («498 повторений всего» vs «499 повторений»). The demo data shows
«0 новых правил» and «0 сегодня». Several headlines promise things their screenshot does not
show. The description names Instituto Cervantes twice with no disclaimer. 2.0 is locked
(scheduled for 2026-11-24), so the custom product pages can be fixed now and the main set
must ship with 2.0.1.

## What Changes

- Demo mode (`-lorito-demo-data`) hides the «Учиться вместе» card, so no unavailable or error
  state reaches a store capture.
- Progress labels say what each number counts. The all-time tile counts graded cards
  (review-items rule); the heatmap total counts every graded answer (cards, conjugations,
  words, CCSE). Today they are both labelled «повторений» and read as a contradiction.
- `DemoSeed`: new cards introduced this week (the weekly recap shows new rules), a few
  reviews already done today, and a first session card about a Russian-speaker trap
  (noun gender «el problema» or ser/estar) instead of the tilde card.
- Scenes:
  - 02Mistakes frames the whole «Частые ошибки» block of that card.
  - 07Recall shows that card's front.
  - 05Exercise captures a listening or dictation exercise.
  - 08Progress headline changes to match the screen (no goal is shown there).
  - Sparse scenes are tightened: 03Exams and 06Variant on iPhone, and the iPad Today left
    column.
- Copy (ru, es-ES, es-MX):
  - add «Lorito не связан с Instituto Cervantes» to the description;
  - lower-case «риоплатский»;
  - use the spare keyword characters.
- Delivery:
  - Re-capture and re-frame the screenshots, and re-render the header and search assets.
  - Before 2026-11-24, after owner approval: new custom product page versions with the
    fixed screenshots.
  - With 2.0.1, after 2.0 is live: main screenshots, description and keywords.
  - The approved in-app event art stays unchanged, so the event's 2026-11-24 start is not
    put at risk.

## Capabilities

### Modified Capabilities
- `app-store-presence`: screenshots show no error or unavailable states; headlines are true
  of their screen; the description carries the Instituto Cervantes disclaimer; custom product
  pages are refreshed independently of the app version.
- `stats-and-streak`: the progress screen labels the card count and the all-answers heatmap
  total differently.

## Impact

- Code and assets:
  - Code: `DemoSeed`, `BuddyCard` call site on Progress (demo flag), `StatsView` labels,
    `ScreenshotUITests`.
  - Copy and media: `fastlane/screenshot_headlines.json`, `fastlane/metadata/{ru,es-ES,es-MX}`,
    `fastlane/screenshots/*`, header and search art in `fastlane/marketing/media/`.
  - Scripts: `tools/create_custom_product_pages.rb`, which needs a mode that adds a new
    version to an existing page.
- Ordering: archive `store-presence-2-0` before this change, because both modify «Benefit-led
  screenshot set».
- App Store Connect writes happen only after the owner approves.
