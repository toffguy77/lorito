## 1. Copy

- [x] 1.1 Promotional text, description, «Что нового» for 2.0 with bundle counts (ru, es-ES, es-MX); lint passes — нужна вычитка
- [x] 1.2 `fastlane/marketing/copy.json`: creative assets, custom product pages, in-app event, featuring nomination — нужна вычитка

## 2. Screenshots

- [x] 2.1 Demo store: DELE A2 date, conjugation and words trainers
- [x] 2.2 `ScreenshotUITests`: eight scenes; headlines
- [x] 2.3 `fastlane snapshot`; frame for ru, es-ES, es-MX; review at size

## 3. Media

- [x] 3.1 Creative assets, event media, featuring art from `design/marketing/` (`tools/render_marketing.sh`)
- [x] 3.2 Re-render the media on the new captures
- [x] 3.3 App previews for iPhone and iPad (`tools/record_app_preview.sh`); check spec with ffprobe

## 4. Review and upload

- [x] 4.1 Owner review page with all copy and media
- [x] 4.2 After approval: metadata, screenshots and previews upload; custom product pages, in-app event, creative assets and nomination in App Store Connect
- [x] 4.3 `openspec validate store-presence-2-0 --strict`
- [ ] 4.4 After 2.0 is approved: assign custom product page keywords (DELE, экзамен / CCSE, гражданство / глаголы, спряжение, субхунтив, subjuntivo); link the approved event to the 2026-11-24 nomination
