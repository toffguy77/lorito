## 1. Domain (TDD)

- [ ] 1.1 Write failing tests: trap created by Опять and by an incorrect attempt; not by Трудно; not for cards without a mistakes section
- [ ] 1.2 Write failing tests: ranking (last failure desc, count desc, card order)
- [ ] 1.3 Write failing tests: resolution after two passing outcomes (study Хорошо/Легко, correct attempt, "Понял"); reopen on a later failure; determinism with injected today
- [ ] 1.4 Implement `PersonalTraps` and `TrapConstants` (`resolveAfterPasses = 2`, `sessionSize = 10`)
- [ ] 1.5 Extend the trap-of-the-day picker with a personal-trap input; tests: prefers personal traps, unchanged behavior when none, same trap within a day

## 2. Persistence

- [ ] 2.1 Add `TrapPracticeEvent` (id, cardID, date, outcome) to Domain + SwiftData record with defaulted fields; `UserDataStore` append/fetch
- [ ] 2.2 Store tests: round-trip and relaunch; CloudKit-compatible schema (optional/defaulted attributes)

## 3. Features

- [ ] 3.1 Today: "Мои ловушки · N" entry when N > 0
- [ ] 3.2 «Мои ловушки» screen: ranked list, mistakes items, failure count, opens reader; top 20 + "показать все"
- [ ] 3.3 Traps session (focus mode): front = first mistakes item, reveal = full section, "Ещё путаю" / "Понял"; writes `TrapPracticeEvent` only; test with fake store that `CardReview` is untouched
- [ ] 3.4 Session summary: link to «Мои ловушки» when the session created new traps

## 4. Validation

- [ ] 4.1 `swift test` green
- [ ] 4.2 `xcodebuild` build; UI test: grade a card Опять → Today shows the traps entry → traps session → "Понял" twice across sessions → trap resolved
- [ ] 4.3 `openspec validate personal-traps --strict`
