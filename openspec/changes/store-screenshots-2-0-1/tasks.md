## 1. Progress labels

- [x] 1.1 Failing test: the progress screen labels the all-time card count and the heatmap total differently (498 cards + 1 conjugation → «498» with «карточек повторено», «499 ответов»); `swift test` fails before the fix
- [ ] 1.2 `StatsView`: tile «карточек повторено», heatmap total «N ответов/ответа/ответ» via `RussianPlural`, matching accessibility label; `swift test` green; check the iPhone and iPad layouts with Dynamic Type AX5

## 2. Demo store and buddy card

- [x] 2.1 Progress gets a `showsBuddy` flag, false under `-lorito-demo-data`; UI test: with demo data, Progress has no `buddy.card`
- [x] 2.2 `DemoSeed.make`: three A2 introductions last week (the recap week), 3 card events today with work still planned, A1-07 is the earliest due item; unit tests pin: weekly recap new rules > 0, studied today > 0, first session item A1-07, Today plan non-empty

## 3. Screenshot scenes

- [x] 3.1 `ScreenshotUITests` 02Mistakes: scroll until «Частые ошибки» is in the top third of the card and fully visible; 07Recall shows the A1-07 front
- [x] 3.2 05Exercise: open a card whose first exercise is dictation or listening; a content test pins that card/exercise kind
- [x] 3.3 03Exams: reviewed the DELE A2 track as a replacement — it shows the fee (≈ 130 €), the examenes.cervantes.es URL and an empty «Готовность» in demo; the list sheet (with the «не связан с Instituto Cervantes» line) stays
- [x] 3.4 `fastlane/screenshot_headlines.json`: 08Progress «Серия дней и долгая память»; 06Variant kept (a longer benefit line wraps to three lines at the framer's fixed size); counts match the bundle (937)
- [x] 3.5 iPad 01Today empty left column: it is the specified dashboard (hero leading, the rest trailing; Today does not use `BalancedColumnsLayout`) — noted in ASO.md, no separate change
- [x] 3.6 Capture on CI or local sims, frame ru/es-ES/es-MX; review all 16 at size: no error states, no zeros in recap/today, numbers consistent

## 4. Copy and media

- [x] 4.1 Failing lint test: a description with «Instituto Cervantes» but without «не связан с Instituto Cervantes» fails; then implement in `tools/lint_metadata.py`; `python3 tools/test_lint_metadata.py` green
- [x] 4.2 Descriptions ru/es-ES/es-MX: add the disclaimer, lower-case «риоплатский»; `python3 tools/lint_metadata.py` passes
- [x] 4.3 Re-render header and search art from the new captures (`tools/render_marketing.sh`); check sizes 3840×1646 / 3840×2560 and no alpha
- [ ] 4.4 Check the app previews (ffprobe + visual pass) against the new seed; re-record only if a frame shows an error or a zero

## 5. Review and upload

- [ ] 5.1 Owner review page with the new screenshots, media and copy diff
- [ ] 5.2 `tools/create_custom_product_pages.rb --new-version`: new CPP versions with the new screens (ru, es-ES, es-MX), promo text kept; after approval run it and submit by 2026-11-17
- [ ] 5.3 After 2.0 is live: version 2.0.1 with build, screenshots, description, keywords (spare characters per ASC search data); submit
- [ ] 5.4 `openspec validate store-screenshots-2-0-1 --strict`
