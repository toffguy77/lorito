## 0. Dependency

- [x] 0.1 `plumaje-design-system` applied (uses `GradeButtons` captions, `PrimaryButton`, focus-mode tokens)

## 1. Content: optional `recall` field (pipeline, TDD)

- [x] 1.1 Document `recall` in `content/schema.md` (one line, ≤ 200 chars, Markdown, Spanish in `*…*`)
- [x] 1.2 Write failing tests in `tools/test_pipeline.py`: valid / empty / multiline / overlong / non-string `recall`; compile writes `recall` only when present
- [x] 1.3 Implement in `tools/validate.py` and `tools/compile.py`
- [x] 1.4 `tools/enrich.py`: add a `--recall` mode that drafts a prompt from the card's Суть/Ключевые моменты for human review (passthrough when no LLM is configured)
- [x] 1.5 Author `recall` for A1 (30 cards) and A2 (29 cards); run `tools/compile.py` _(drafts — нужна вычитка)_

## 2. Domain (TDD)

- [x] 2.1 `Card.recall: String?` decoded from the bundle; tests for present/absent
- [x] 2.2 `IntervalPreview.captions(for:today:)` — failing tests that, for new/learning/review states, each caption equals the formatted `SpacedRepetitionScheduler.schedule` interval; 0 → "сегодня"; Russian plurals (1 день, 2 дня, 5 дней, 11 дней, 21 день); ≥ 30 → "≈ N мес."
- [x] 2.3 `SessionSummary.make(grades:cardsByID:stats:)` — tests for studied count, first-try share, revisit themes (top 3 by count), new-record flag
- [x] 2.4 `DailyTrap.pick(candidates:studiedIDs:day:)` — tests: deterministic per day (stable hash, not `hashValue`), prefers studied, nil when empty; extract first bullet of the `.mistakes` callout via `CardBodyParser`

## 3. Features

- [x] 3.1 `StudySessionModel`: `isRevealed`, `reveal()`, reset on advance; `captions` for the current card; collect session grades for the summary. Tests: grading impossible before reveal; reset after advance; captions match Domain
- [x] 3.2 `StudySessionView`: front side (chip, title, recall prompt, card stack visual, hint) → "Показать ответ" → body + captioned `GradeButtons` (mockups `CardFront` / `CardBack`)
- [x] 3.3 Completion view "¡Olé!": summary tiles, streak tile with record badge, revisit themes, "Готово" (mockup `SessionDone`)
- [x] 3.4 `TodayModel` exposes the daily trap; `TodayView` renders "Ловушка дня" and opens the card reader on tap
- [x] 3.5 Accessibility: "Показать ответ" is first VoiceOver focus on the front; captions read as "Хорошо, через 3 дня"

## 4. Validation

- [x] 4.1 `swift test` and `python3 tools/test_pipeline.py` green
- [x] 4.2 UI test: start session → front visible, no grade buttons → reveal → grade → next card on front side → finish → summary visible
- [x] 4.3 `openspec validate recall-first-study --strict`
