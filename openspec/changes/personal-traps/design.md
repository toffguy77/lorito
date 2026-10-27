## Context

`CardBodyParser` lifts «Частые ошибки» into a typed `.mistakes` callout;
`learning-platform-foundation` (dependency) moves it into Domain, defines the
local learning day, item kinds, and the rule that only the first graded review of
an item per learning day updates memory. Answering an exercise writes both an
attempt record and a graded `StudyEvent` through `GradingService`. The trap of
the day (`study-flow`, from archived `recall-first-study`) picks deterministically
per day from in-scope cards with a mistakes section, preferring studied cards.

## Goals / Non-Goals

**Goals:** a personal, self-cleaning list of the user's own traps built from data
we already record; a short session that targets them; a better trap of the day.

**Non-Goals:** per-bullet tracking inside a mistakes section; new content; SRS
changes; ML ranking; traps for non-card items (conjugations, words).

## Decisions

**Single evidence source.** Only `StudyEvent`s of `.card` items count. Attempt
records are ignored for traps because each attempt already produced a graded
study event — counting both would double every exercise failure. Per item and
learning day only the first graded event counts (mirrors foundation rule 5).

**Failure / pass.** Failure = first-of-day Опять. Pass = first-of-day Хорошо or
Легко, or «Ясно» in the traps session. Трудно is neutral. Two passes after the
last failure resolve the trap (`TrapConstants.resolveAfterPasses = 2`); a new
failure reopens it.

**Derived, not stored.** The list is a pure function of study events,
trap-practice events, the catalog, the scope and injected today. Only traps-session
outcomes are stored (`TrapPracticeEvent`: id, cardID, date, outcome) because they
are deliberately outside SRS.

**Scope filter.** Traps outside the current included scope are hidden, not
deleted; they reappear when the scope includes them. This matches the trap of the
day, whose candidates are in-scope cards.

**Ranking.** Last failure learning day desc, failure count desc, card order.

**Traps session is not SRS.** Front: first «Частые ошибки» item; back: the whole
section, card title, link to the card. Actions «Ещё путаю» / «Ясно» (gender-neutral).
Up to `TrapConstants.sessionSize = 10` traps.

**Trap of the day.** The picker gains an input: in-scope personal trap ids. When
non-empty it chooses among them with the same per-day stable hash.

**Copy.** «Мои ловушки · N» keeps the noun before the number; the accessibility
label uses `RussianPlural` («1 ловушка / 2 ловушки / 5 ловушек»).

## Risks / Trade-offs

- [A trap lingers for a card the user never revisits] → it stays visible with its
  date; the traps session resolves it quickly.
- [Long list] → Today shows the count; the list shows the top 20 with
  «показать все».
- [Optimistic «Ясно»] → study grades also count; a later Опять reopens the trap.

## Migration Plan

Additive. Existing histories produce traps from past first-of-day Опять grades.
`TrapPracticeEvent` follows `cloudkit-schema-release` (optional fields, mapping,
dev schema export, production deploy). Rollback: hide the UI.
