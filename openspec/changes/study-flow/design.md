## Context

Lorito's foundation is in place: a compiled content bundle (levels A1–C2, themes, cards with frontmatter + Markdown bodies using the Суть / Ключевые моменты / Ошибки / Полезно callouts), a SwiftData + CloudKit user-data store (`CardReview`, `StudyLog`, `UserSettings`), a pure SM-2 scheduler (`srs-engine`), a daily-queue composer (`daily-plan`), and the "Modern Calm" design system with the components this change reuses. What is missing is the user-facing surface: there is no way to see today's work, study and grade a card, or browse the catalog.

This change adds those screens in the `Features` layer and the Markdown rendering they need. It deliberately consumes — and does not reimplement — the queue logic (`daily-plan`), the SM-2 transitions (`srs-engine`), content loading (`content-model`), persistence (`app-foundation`), and the visual components (`design-system`). The UI in this app is in Russian.

## Goals / Non-Goals

**Goals:**
- A Today screen that summarizes the day's queue (segmented day-progress indicator + due/new counts) with a clear start action and correct empty/all-done states.
- A study session that renders the current card, offers the four SM-2 grade buttons, applies the `srs-engine` update and writes a `StudyLog` entry per grade, advances, completes, and survives mid-session exit with progress intact.
- A catalog to browse levels → themes → cards with per-card status, read any card, and suspend/unsuspend.
- A shared Markdown renderer that maps the four callout sections to design-system callout blocks and renders tables.

**Non-Goals:**
- Queue selection / due-date math (owned by `daily-plan`) and SM-2 transition rules (owned by `srs-engine`).
- Practice exercises (later phase).
- Onboarding, level/theme selection, and reminders (separate changes).
- Defining or restyling design-system components or persistence models (owned by `bootstrap-foundation`).

## Decisions

- **Three feature areas behind one root navigation.** Today and Catalog are top-level destinations (e.g. a tab/segmented root); the study session is presented modally over Today so that dismissing it returns to Today's refreshed state. Alternative — pushing the session onto Today's navigation stack — was rejected because a full-screen, focused session that owns its own dismissal models the "study mode" better and keeps Today's stack clean.
- **Screens read logic, never own it.** The Today and session view-models call into `daily-plan` for the queue/counts and into the `srs-engine` apply-and-persist operation on each grade; the catalog reads `content-model` and `CardReview`. This keeps this change behavioral and lets the queue/SM-2 contracts change underneath without UI rework.
- **Persist each grade immediately (no session-end batch).** Each grade triggers the `srs-engine` apply-and-persist call and a `StudyLog` write before advancing, so mid-session exit and crashes lose nothing and resumption naturally continues on the next ungraded card. Alternative — buffering grades and committing at session end — was rejected because it risks losing progress on interruption, the exact case the requirements call out.
- **Resumption is derived, not a stored cursor.** "Where the user left off" is recomputed from the live queue (`daily-plan`) minus cards already graded today (reflected in `CardReview`/`StudyLog`), rather than persisting an explicit session pointer. This avoids a stale-cursor bug class and means a re-entered session simply shows the next card the queue still considers outstanding.
- **Markdown rendering — parse to a typed block model, then render with SwiftUI.** The renderer pre-parses each card body into a sequence of typed blocks (paragraph, the four named callouts, table, list, etc.), recognizing the callout sections by their headings and emitting the corresponding design-system callout block, and renders tables with a dedicated table view. Alternatives considered: (a) `AttributedString(markdown:)` / `Text(markdown:)` alone — rejected because it does not render tables or block-level callouts; (b) a full third-party Markdown-rendering package — viable and may back the inline/leaf formatting, but the callout-section and table mapping is owned by our renderer so the visual contract stays in the design system. The exact inline-Markdown library is an implementation detail recorded during build; the block model and callout/table contract are fixed here. Both the session and the catalog reader use this one renderer so a card looks identical in both.
- **Status display is a presentation mapping, not new state.** The catalog derives each row's badge (new / learning / review / due / suspended) from the existing `CardReview` fields (status + dueDate vs. today); "due" is `review` whose dueDate has arrived. No new persisted field is introduced.
- **Suspend/unsuspend only sets `CardReview.status`.** The catalog mutates the existing status field (creating a `CardReview` if none exists) and persists it; exclusion from scheduling is honored by `srs-engine`/`daily-plan`, not re-specified here. Unsuspend restores a non-suspended status so the card re-enters normal scheduling.

## Risks / Trade-offs

- **Today's counts can drift from a live session** (cards graded in the session must be reflected when returning) → counts and progress are recomputed from `daily-plan` on appearance rather than cached, so returning from a session always shows fresh numbers.
- **CloudKit sync latency on suspend/grade** → writes go to the local SwiftData store first (sync is asynchronous), so the UI reflects changes immediately and sync converges in the background; no UI blocks on a CloudKit round-trip.
- **Markdown variety across 165 hand-migrated cards** (tables, nested lists, mixed callout headings) → the renderer degrades gracefully (unrecognized blocks render as plain Markdown rather than failing) and the callout recognition matches the documented heading convention; malformed bodies surface in content validation, not as crashes.
- **Resumption-by-derivation depends on graded cards being excluded from the recomputed queue** → relies on `daily-plan` honoring `CardReview` updates the same day; if a graded-but-still-due card could reappear, the session would loop, so the contract assumes a graded card is no longer "outstanding for today".

## Open Questions

- Should the completion state offer an explicit "study ahead / extra cards" affordance, or strictly end the day? (Assumed: strictly end; extra-study is out of scope here.)
- Should the catalog allow opening a card directly into a single-card study/grade flow, or remain read-only plus suspend/unsuspend? (Assumed: read-only plus suspend/unsuspend; grading happens only in the daily session.)
