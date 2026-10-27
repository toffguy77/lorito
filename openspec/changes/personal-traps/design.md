## Context

`CardBodyParser` lifts «Частые ошибки» into a typed `.mistakes` callout. Study
grades are recorded as study events (`StudyLog`); exercise attempts are persisted
with `correct` and the applied grade (`practice-exercises`). The trap of the day
(`study-flow`, from archived `recall-first-study`) picks deterministically per
day from scope cards with a mistakes section, preferring studied cards.

## Goals / Non-Goals

**Goals:** a personal, self-cleaning list of the user's own traps built from data
we already record; a short session that targets them; a better trap of the day.

**Non-Goals:** per-item (bullet-level) tracking inside a mistakes section; new
content authoring; changing SRS scheduling; ML ranking.

## Decisions

**Derived, not stored.** The trap list is a pure function of study events,
exercise attempts, trap-practice events, the catalog and injected today. Only
the traps-session outcomes need a new record (`TrapPracticeEvent`), because they
are deliberately outside SRS. Derivation keeps multi-device sync trivial.

**Failure signal.** A failure is a study event with grade Опять, or an exercise
attempt with `correct == false`, for a card that has a mistakes section. Трудно
is not a failure (the user did recall).

**Ranking.** Sort by last failure date descending, then failure count descending,
then card order for determinism.

**Resolution.** Count passing outcomes after the card's last failure: study
grades Хорошо/Легко, exercise attempts with `correct == true`, and "Понял" in the
traps session. Two passing outcomes resolve the trap; a new failure reopens it.
`TrapConstants.resolveAfterPasses = 2`.

**Traps session is not SRS.** Front: the first «Частые ошибки» item; back: the
whole mistakes section plus the card title and a link to the card. Outcomes write
`TrapPracticeEvent` only. Rationale: an out-of-schedule SM-2 review would
distort intervals; the session is targeted rehearsal, the SRS stays the source
of truth for scheduling. Session size: up to `TrapConstants.sessionSize = 10`.

**Trap of the day.** The existing picker gains an input: the personal trap card
ids. When non-empty, it chooses among them with the same per-day stable hash;
otherwise behavior is unchanged.

## Risks / Trade-offs

- [A trap stays forever for a card the user skips] → also resolved implicitly
  only by passes; users can open the card or run the session. Acceptable.
- [Long list overwhelms] → Today shows the count; the list shows top 20 with
  "показать все".
- [Self-assessment in traps session is optimistic] → study grades also count;
  a later Опять reopens the trap.

## Migration Plan

Additive. Existing histories immediately produce a trap list from past Опять
grades and failed attempts. Rollback: hide the UI; the new record type is
ignored.
