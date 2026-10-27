## Context

Current Russian metadata (fastlane/metadata/ru): subtitle «Испанский по
карточкам»; keywords «испанский,español,язык,карточки,интервальное
повторение,грамматика,слова,учить,SRS,A1»; description leads with "простой и
спокойный способ учить испанскую грамматику и лексику". The bundle display name
is «Lorito Español». The app is free, offline, without account or ads.

Field limits (Apple): name 2–30 characters and subtitle ≤ 30 characters
(https://developer.apple.com/help/app-store-connect/reference/app-information/app-information);
promotional text ≤ 170 characters, description ≤ 4000 characters, keywords
"up to 100 bytes", each keyword longer than two characters, no app or company
names (https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

## Goals / Non-Goals

**Goals:** the first screen of the product page states the differentiator;
metadata matches real features; limits are checked automatically.

**Non-Goals:** paid acquisition, Apple Search Ads, other storefront languages
(English/Spanish pages are a later change), predicting ranking gains.

## Decisions

**Name and subtitle.** Candidate name «Lorito: испанская грамматика» (28
characters) keeps the brand and adds the core search term; subtitle
«Объяснения по-русски, A1–C2» (27 characters). Alternative if a rename is
undesirable: keep «Lorito Español» and put «Грамматика по-русски, A1–C2» in the
subtitle. Final pick is a product decision recorded in tasks.

**Keywords, stage 1** (no exam terms): grammar intents not already in name or
subtitle, e.g. `español,subjuntivo,ser,estar,спряжение,глаголы,правила,
карточки,SRS,B1,C1`. **Stage 2** (after the exam path ships): swap low-value
terms for `DELE,CCSE`. Exact list chosen when implementing, under the limit.

**Byte vs character limit.** Apple documents keywords as 100 bytes, while the
current keyword string is 85 characters but 149 UTF-8 bytes (Cyrillic is two
bytes per letter) and is live. The lint therefore enforces ≤ 100 characters as
the hard limit and reports UTF-8 bytes as a warning; confirm the real
enforcement in App Store Connect when uploading.

**Description structure.** 1) one-line promise; 2) the problem (rules
explained for English speakers, not for Russian speakers); 3) what is inside
— numbers taken from the repo at release time (currently 159 cards, 892
exercises); 4) how a day works (план → вспомнить → оценить); 5) free, offline,
no account, no ads; 6) who it is for (beginners to C2, relocants, exam
takers — the last only after stage 2).

**Screenshots.** Six scenes per device class, each with a headline above the
device frame: Сегодня (plan), card front «Сначала вспомни», revealed card with
«Частые ошибки», exercise, progress, catalog. iPad set uses the regular-width
layouts once `ipad-plumaje-layouts` ships; until then, current iPad captures.

**Lint.** `tools/lint_metadata.py` reads every `fastlane/metadata/*/*.txt`
field it knows and fails on: over-limit, empty required field, keyword ≤ 2
characters, duplicate keyword, keyword repeating a name word.

## Risks / Trade-offs

- [Renaming the app affects recognition] → keep «Lorito» as the first word.
- [Exam keywords before the feature → review rejection] → staged policy.
- [Ranking impact is unknown] → compare impressions and product-page
  conversion in App Store Connect analytics for 4 weeks before/after.

## Migration Plan

Ship stage 1 with the next app version (name/subtitle change requires a new
version). Promotional text can be changed anytime. Stage 2 ships with the exam
path release. Rollback: restore previous metadata files from git.
