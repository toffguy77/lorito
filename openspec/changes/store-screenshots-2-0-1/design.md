# Design

## Context

- 2.0.0 is `PENDING_DEVELOPER_RELEASE`, with release scheduled for 2026-11-24 10:00 MSK. Its
  screenshots, description and keywords cannot change before then. Custom product pages
  (CPPs) and the in-app event are reviewed separately from the app version.
- `store-presence-2-0` is still open and already modifies «Benefit-led screenshot set» to the
  eight-scene version. This change's delta is written against that eight-scene text, so
  `store-presence-2-0` is archived first (on release).
- The 498 / 499 mismatch is not a counting bug:
  - `StatsCalculator.compute` counts `isCard` events, as the review-items rule requires for
    card counts.
  - `dailyActivity` counts every graded event. The spec says "total number of grade events".
  - The screenshot run grades one conjugation (04Conjugation) before 08Progress.
  - Both numbers are labelled «повторений», so they read as a contradiction.
- The iCloud note comes from `BuddyCard` in state `.unavailable`. The simulator has no iCloud
  account.
- `DemoSeed.make` writes events only for cards that already have a `ReviewState`. Nothing is
  introduced this week (so «0 новых правил»), and nothing happens today (so «0 сегодня»). The
  first session card is the first due A1 card, which is the tilde card A1-1.

## Goals / Non-Goals

**Goals:**
- Store captures with no error states, consistent numbers and true headlines.
- Fixed CPP screenshots live before 2026-11-24.
- The main set ships with 2.0.1.

**Non-Goals:**
- Changing the approved in-app event media.
- Adding a goal widget to Progress.
- New app previews. They are re-recorded only if the seed change visibly breaks them.

## Decisions

1. **Hide «Учиться вместе» in demo mode, not fake a paired state.**
   - The app passes a `showsBuddy` flag, false under `-lorito-demo-data`, to the progress view.
   - Alternative: seed a paired buddy. This needs a fake CloudKit share and partner data, is
     brittle, and advertises a feature the screenshot set doesn't headline.

2. **Fix the labels, not the counts.**
   - Both definitions are specified and correct.
   - The all-time tile becomes «карточек повторено». The heatmap total becomes «N ответов»
     (plural forms via `RussianPlural`), and its accessibility label matches.
   - Alternative: count only cards in the heatmap. The heatmap would then hide days of
     conjugation and word practice, and the streak counts those days, so it would also
     disagree with the streak.

3. **Headline for 08Progress becomes «Серия дней и долгая память»** instead of showing a goal
   on Progress. The goal countdown already appears on 01Today.

4. **Seed shape (`DemoSeed.make`):**
   - Three A2 cards get their first events in the previous Monday–Sunday week (the week the
     recap reports).
   - Today gets 3 card events before capture, on cards not due today, so «сегодня» > 0 while
     the plan is unchanged. No conjugation event: it would shift the trainer's first prompt
     that 04Conjugation types into.
   - The Today hero must still show work left: today's events must not exhaust due items.
   - A1-07 (noun gender, «el problema») is made the earliest due item, so the session opens on
     it.
   - Streak, best streak and «дней подряд» are derived from these events; the
     headlines don't quote numbers.

5. **02Mistakes framing:** scroll until the «Частые ошибки» header is near the top of the
   visible card, instead of swiping until the element is merely hittable.
   - `ScreenshotUITests` gets a helper that swipes with a small offset and checks that the
     header's `frame.minY` is inside the top third.

6. **05Exercise:** no card opens on dictation, so the capture uses the existing UI-testing
   filter `-lorito-practice-types dictation` on A1-11 and types the answer.
   - A content test pins A1-11's dictation text, so a content edit can't silently change the
     scene.
   - The headline keeps «937 упражнений» with the count read from the bundle.

7. **Sparse scenes:**
   - 03Exams: the list sheet stays. The DELE A2 track was considered, but it shows the fee,
     the examenes.cervantes.es URL and an empty «Готовность» (no demo attempts).
   - 06Variant: screen and headline kept; a longer benefit line wraps to three lines at the
     framer's fixed font size.
   - iPad 01Today empty left column: check `BalancedColumnsLayout` on Today at
     2752×2064. If it is a layout bug it gets its own fix change. This change only records
     the finding.

8. **Disclaimer enforced by lint:** `tools/lint_metadata.py` fails when a description
   mentions Instituto Cervantes without «не связан с Instituto Cervantes».

9. **CPP refresh:**
   - `tools/create_custom_product_pages.rb --new-version` creates a new
     `appCustomProductPageVersion` per existing page and uploads the new screens for ru, es-ES
     and es-MX. It copies the promotional text and keeps keywords on the page.
   - It is run only after owner approval.

## Risks / Trade-offs

- [CPP review takes longer than the time left before 2026-11-24] → Submit by 2026-11-17. If a
  version is not approved, the old version stays live, which is no worse than today.
- [The new seed changes counts in the app previews] → Re-check the previews with ffprobe and a
  visual pass, and re-record only if a frame shows an error or a zero.
- [2.0.1 needs a build only to carry the metadata] → It also carries the Progress label fix,
  a real UI change, so the build is warranted.

## Migration Plan

1. Implement and capture, then show the owner a review page.
2. After approval: CPP new versions (before 11-24).
3. After 2.0 is live: create 2.0.1 with the build, screenshots, description and keywords, and
   submit.
4. Archive `store-presence-2-0` on the 2.0 release, and this change on the 2.0.1 release.

Rollback: an unapproved CPP version leaves the previous version live. Metadata reverts by
re-uploading from git.

## Open Questions

- The spare keyword characters: which words go in (e.g. «лексика», «DELE A2» variants) is
  decided against App Store Connect search data after 2.0 is live. This doesn't change the
  tasks.
