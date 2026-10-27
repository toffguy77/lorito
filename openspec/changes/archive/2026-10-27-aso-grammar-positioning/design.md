## Context

Current Russian metadata (fastlane/metadata/ru): subtitle «Испанский по
карточкам»; keywords «испанский,español,язык,карточки,интервальное
повторение,грамматика,слова,учить,SRS,A1»; description leads with "простой и
спокойный способ учить испанскую грамматику и лексику". The bundle display name
is «Lorito Español». The app is free, offline, without account or ads.

Field limits (Apple): name 2–30 characters and subtitle ≤ 30 characters
(https://developer.apple.com/help/app-store-connect/reference/app-information/app-information);
promotional text ≤ 170 characters, description ≤ 4000 characters, keywords
documented as "up to 100 bytes", each keyword longer than two characters, no
app or company names
(https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

## Goals / Non-Goals

**Goals:** the first screen of the product page states the differentiator;
Russian speakers find Lorito in Russia, Spain and Latin America; metadata
matches real features; limits are checked automatically.

**Non-Goals:** paid acquisition, Apple Search Ads, Spanish- or
English-language marketing pages for native speakers, predicting ranking gains.

## Decisions

**Name and subtitle (owner decision, ru).** Name «Lorito: испанский язык»
(22 characters), subtitle «Грамматика по-русски, A1–C2» (27 characters).
Rationale: the head queries are «испанский язык» / «учить испанский»; Apple
does not reliably match Russian inflections, so the inflected form «испанская»
goes into keywords; the brand «Lorito» stays first.

**Keyword limit is counted in characters.** Apple documents 100 bytes, but the
published keyword string is 85 characters / 149 UTF-8 bytes and was accepted,
so the lint enforces ≤ 100 characters; confirming the limit on upload is a task.

**Keywords.** Stage 1 (90 characters, no word repeated from name or
subtitle): `испанская,учить,правила,глаголы,спряжение,времена,субхунтив,
subjuntivo,карточки,упражнения`. Stage 2 (with the exam path, 92 characters):
`испанская,учить,правила,глаголы,спряжение,субхунтив,subjuntivo,DELE,CCSE,
экзамен,гражданство`. Every keyword is longer than two characters; level codes
(B1, C1) are not used.

**Cross-localization for the diaspora.** Storefronts index specific
localizations; per aso.dev, Mexico and Argentina index es-MX plus en-GB
(https://aso.dev/metadata/cross-localization/), Spain is paired with es-ES
(https://aso.dev/app-store-connect/app-store-localizations/), and Russian is
paired only with Russia — so Russian metadata is invisible to Russian speakers
abroad. We add es-ES and es-MX localizations whose name, subtitle, keywords and
description are in Russian, aimed at Russian speakers. aso.dev states any
localization may be filled with another language. Risk: App Review may question
non-Spanish text in a Spanish localization; mitigation — description first line
states the app is for Russian speakers learning Spanish; treat as an experiment
measured by impressions/installs in those storefronts, revert if rejected.
The Spain row of the aso.dev table was not visible when checked; confirm
Spain's indexed localizations before relying on es-ES alone.

**Description structure.** 1) one-line promise; 2) the problem (rules are
explained for English speakers, not Russian speakers); 3) what is inside —
counts taken from the build's content bundle; 4) how a day works; 5) free core,
offline, no account, no ads; 6) in-app purchases disclosed once `lorito-pro`
ships; 7) who it is for (exam takers only after stage 2).

**Screenshots.** Six scenes per device class with a headline above the device:
Today plan, card front «Сначала вспомни», revealed card with «Частые ошибки»,
exercise, progress, catalog. UI tests launch with a seeded demo store
(fixed streak, history, reviews) so screens are full and deterministic.

**Lint and upload.** `tools/lint_metadata.py` checks every known field of every
localization. Upload goes through the existing fastlane `submit`/`deliver` lane
using the App Store Connect API key from `secrets/asc.env`; the upload log is
checked for rejected fields to confirm accepted lengths.

## Risks / Trade-offs

- [Renaming affects recognition] → «Lorito» stays the first word.
- [Exam keywords before the feature → rejection] → staged policy.
- [Cross-localization rejected] → isolated in two localizations; remove them.
- [Ranking impact is unknown] → compare App Store Connect impressions and
  conversion for 4 weeks before/after, per storefront.

## Migration Plan

Stage 1 ships with the next app version (name change needs a new version).
Cross-localizations ship in the same version. Stage 2 and the IAP disclosure
ship with their features. Rollback: restore metadata from git and re-upload.
