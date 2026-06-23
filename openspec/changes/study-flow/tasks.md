## 1. Markdown rendering (shared)

- [ ] 1.1 Define the typed block model for a card body (paragraph, list, table, and the four named callouts Суть / Ключевые моменты / Ошибки / Полезно)
- [ ] 1.2 Implement the parser that maps a card's Markdown body to the block model, recognizing the four callout sections by their headings
- [ ] 1.3 Implement the SwiftUI renderer that draws each block, mapping callout blocks to the design-system callout components and tables to a table view (callouts and tables both supported)
- [ ] 1.4 Verify rendering against real bundled cards containing tables and all four callout variants; confirm graceful fallback for unrecognized blocks

## 2. Today screen

- [ ] 2.1 Add the Today view-model that reads the day's queue and the due/new counts from `daily-plan` (no queue computation here)
- [ ] 2.2 Build the Today screen: segmented day-progress indicator + counts rendered as "N на повторение + M новых"
- [ ] 2.3 Add the primary start action, enabled only when the queue is non-empty, opening the session on the first card
- [ ] 2.4 Implement the empty state (nothing due) and the all-done state (day completed) as distinct states
- [ ] 2.5 Recompute counts and progress on appearance so returning from a session shows fresh numbers

## 3. Study session

- [ ] 3.1 Add the session view-model exposing the current card and advancing through the queue from `daily-plan`
- [ ] 3.2 Build the session screen: study-card container with level/theme chip, title, and the shared Markdown body renderer
- [ ] 3.3 Add the four SM-2 grade buttons (Опять / Трудно / Хорошо / Легко) from the design system
- [ ] 3.4 On grade: call the `srs-engine` apply-and-persist operation for the current card's `CardReview` (reference), write a `StudyLog` entry for the card+grade, then advance — persisting each grade immediately
- [ ] 3.5 Implement the completion state when the queue is exhausted; dismissing it returns to the Today all-done state
- [ ] 3.6 Implement mid-session exit; verify already-graded cards stay persisted and re-entry resumes on the next ungraded card (resumption derived from the live queue minus cards graded today)

## 4. Catalog

- [ ] 4.1 Build levels → themes → cards browsing from the content bundle, preserving defined order
- [ ] 4.2 Implement the per-row status mapping from `CardReview` (new / learning / review / due / suspended), where due = review with dueDate reached and new = no review yet
- [ ] 4.3 Build the card reader reusing the shared Markdown renderer (chip, title, callouts, tables)
- [ ] 4.4 Add suspend / unsuspend from the reader, setting `CardReview.status` (creating a `CardReview` if absent) and persisting it
- [ ] 4.5 Verify the suspended status is reflected back in the theme listing after returning

## 5. Navigation & integration

- [ ] 5.1 Wire Today and Catalog as top-level destinations and present the session modally over Today
- [ ] 5.2 Confirm all screens consume foundation contracts only (design-system components, content-model, CardReview/StudyLog) and the `daily-plan` / `srs-engine` operations — no redefinition

## 6. Validation

- [ ] 6.1 Run `openspec validate study-flow --strict` and fix until it reports the change is valid
