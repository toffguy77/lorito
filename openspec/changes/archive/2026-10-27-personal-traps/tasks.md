## 0. Dependencies

- [x] 0.1 `learning-platform-foundation` applied (`CardBodyParser` in Domain, `ItemKind`, local learning day, first-grade-per-day rule)
- [x] 0.2 `cloudkit-schema-release` applied (schema workflow)

## 1. Domain (TDD)

- [x] 1.1 Write failing tests: trap from first-of-day Опять on a `.card`; an exercise failure (attempt + study event) counts once; later same-day grades ignored; not by Трудно; not without a mistakes section; non-card items ignored
- [x] 1.2 Write failing tests: scope filter hides out-of-scope traps and restores them when scope widens
- [x] 1.3 Write failing tests: ranking (last failure day desc, count desc, card order)
- [x] 1.4 Write failing tests: resolution after two passes (first-of-day Хорошо/Легко, «Ясно»); reopen on a later failure; determinism with injected today
- [x] 1.5 Implement `PersonalTraps` and `TrapConstants` (`resolveAfterPasses = 2`, `sessionSize = 10`)
- [x] 1.6 Extend the trap-of-the-day picker with in-scope personal trap ids; tests: prefers personal traps, unchanged when none, stable within a day

## 2. Persistence

- [x] 2.1 `TrapPracticeEvent` (id, cardID, date, outcome) in Domain + record with optional/defaulted properties, mapped both ways in `SwiftDataUserDataStore`
- [x] 2.2 Store round-trip test; export dev schema per `cloudkit-schema-release` — (owner): `-LoritoInitCloudKitSchema` + `cktool export-schema` (new record type `CD_TrapPracticeRecord`)

## 3. Features

- [x] 3.1 Today: «Мои ловушки · N» entry when N > 0; accessibility label via `RussianPlural` (1/2/5 forms)
- [x] 3.2 «Мои ловушки» screen: ranked in-scope list, mistakes items, failure count, opens reader; top 20 + «показать все»
- [x] 3.3 Traps session (focus mode): front = first mistakes item, reveal = full section, «Ещё путаю» / «Ясно»; writes `TrapPracticeEvent` only; fake-store test that review state is untouched
- [x] 3.4 Session summary: link to «Мои ловушки» when the session created new traps

## 4. Validation

- [x] 4.1 `swift test` green
- [x] 4.2 `xcodebuild` build; UI test: grade a card Опять → Today shows the entry → traps session → «Ясно» on two different days → trap resolved (two tests: the second day is seeded via `-lorito-seed-trap`, since a UI test can't span learning days)
- [x] 4.3 `openspec validate personal-traps --strict`
