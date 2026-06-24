## Why

Lorito has a populated content bundle (`bootstrap-foundation`), a pure SM-2 scheduler (`srs-engine`), and a daily-queue composer (`daily-plan`), but nothing the user can actually open and study. This change adds the user-facing surface of the app: the screens where a learner sees what is due today, studies cards one by one and self-grades them, and browses the included catalog to read or suspend any card.

The scheduling and queue *logic* already lives in the referenced changes and is deliberately kept there. This change is purely about **screens and their wiring** — rendering content (Markdown with the Суть / Ключевые моменты / Ошибки / Полезно callouts and tables), reusing the existing design-system components, invoking `srs-engine` when a grade is tapped, writing a `StudyLog` entry, and persisting progress so a session can be interrupted and resumed. Keeping this layer thin and behavioral means the queue and SM-2 contracts can evolve underneath it without reworking the UI.

## What Changes

- Add a **TODAY screen** that shows the day's queue from `daily-plan` using the segmented day-progress indicator and the counts (e.g. "N на повторение + M новых"), offers a primary action to start studying, and renders the correct empty / all-done state when nothing is due.
- Add a **STUDY-CARD (session) screen** that renders the current card — level/theme chip, title, and Markdown body with callouts and tables — inside the study-card container, presents the four SM-2 grade buttons (Опять / Трудно / Хорошо / Легко), and on each grade applies the `srs-engine` update (reference), writes a `StudyLog` entry, and advances to the next card; the session ends to a completion state when the queue is exhausted, and exiting mid-session preserves progress.
- Add **CATALOG browsing**: navigate included levels → themes → cards; each card row shows its status (new / learning / review / due / suspended); opening a card reads it (same Markdown rendering as the session); and a card can be suspended / unsuspended, which sets `CardReview.status`.
- Add a **Markdown rendering capability** (covered within `study-flow`) that supports the four callout sections and tables, shared by the session and catalog readers.

This change delivers no new scheduling rules, no queue-selection logic, and no practice exercises. It composes the existing foundation, `srs-engine`, and `daily-plan` contracts into navigable screens.

## Capabilities

### New Capabilities
- `study-flow`: The TODAY screen (queue summary via the segmented day-progress indicator and due/new counts, start action, empty/all-done state), the STUDY-CARD session screen (render current card with chip/title/Markdown callouts+tables, four SM-2 grade buttons, grade applies the `srs-engine` update and writes a `StudyLog` entry then advances, completion state, resumable mid-session exit), and the Markdown rendering of card bodies (callout sections + tables) shared across the app.
- `catalog`: Browsing the included content as levels → themes → cards with per-card status (new / learning / review / due / suspended), opening any card to read it, and suspending / unsuspending a card by setting `CardReview.status`.

### Modified Capabilities
<!-- None — the foundation specs (app-foundation, content-model, content-pipeline, design-system) and the adjacent srs-engine / daily-plan specs are not archived yet, so this change introduces no MODIFIED deltas. It builds on those contracts (CardReview, StudyLog, design-system components, the daily queue, the apply-grade operation) without redefining them. -->

## Impact

- **Code (added, not in scope to author here)**: `Features`-layer SwiftUI screens — Today, Study session, and Catalog (levels/themes/cards list + card reader) — plus a Markdown-to-callouts/tables renderer in the `DesignSystem`/`Features` layer and the view-model wiring that reads the `daily-plan` queue, calls the `srs-engine` apply-and-persist operation, and writes `StudyLog`.
- **Foundation contracts consumed (not modified)**: `content-model` levels/themes/cards and card bodies; `app-foundation` `CardReview` (`status ∈ {new, learning, review, suspended}`) and `StudyLog`; `design-system` components — level/theme chip, segmented day-progress indicator, callout blocks, SM-2 grade buttons, study-card container.
- **Adjacent contracts consumed (not authored here)**: `daily-plan` for the day's queue and the due/new counts; `srs-engine` for the apply-grade-and-persist operation.
- **No new backend, no schema changes**: screens read bundled content and the existing user-data store; suspend/unsuspend and grading mutate already-defined `CardReview` fields and append `StudyLog` rows.
- **Out of scope**: practice exercises; queue selection and SM-2 rules (owned by `daily-plan` and `srs-engine`).
