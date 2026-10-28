## 1. Pipeline (TDD)

- [x] 1.1 Failing tests: coverage map — card with neither rule nor entry fails; card in both fails; unknown card fails; empty reason fails; no map file → check skipped (fixtures)
- [x] 1.2 Failing tests: `tenses` union; `exclude_tenses` drops look-alikes; participles with `inflect` add -a/-os/-as
- [x] 1.3 Implement in `tools/lens.py`; document `coverage.json` and the set keys in `content/schema.md`

## 2. Rules (generated — нужна вычитка)

- [x] 2.1 Coverage map for every card without a rule, with reasons
- [x] 2.2 A1 rules: question words, demonstratives, possessives, pronouns/forms of address, ser de, hay, tener expressions, reflexive verbs, double negation, muy/mucho, time, dates, al/del
- [x] 2.3 A2 rules: indefinido, imperfecto, futuro, condicional, perífrasis, object pronouns, imperatives, comparatives, superlatives, irregular comparatives, -mente, indefinites, connectors, relatives, hace/desde hace
- [x] 2.4 B1 rules: concession/condition conjunctions, relatives with subjunctive, imperfecto de subjuntivo, futuro/condicional perfecto, probability, si + presente, reported speech, passive, pasiva refleja, change of state, el cual / cuyo, opinion
- [x] 2.5 B2–C1 rules: perfect and pluperfect subjunctive, de haber + participle, regrets, causal, concessive, temporal/final conjunctions, reported speech with condicional, se accidental, prepositional verbs, perífrasis B2, estar + participio, lo + adj / lo de, futuro de subjuntivo, queísmo/dequeísmo, al + infinitivo, una vez + participio, el hecho de que, C1 connectors
- [x] 2.6 Existing rules gain links where the card is the topic: ir-a-infinitivo → A2-08; preterito-perfecto, ayer-indefinido → A2-06 (B1-01 / B1-09 go to the coverage map: a second card on the main subjunctive highlights would add a step to the core flow)
- [x] 2.7 `validate.py` / `compile.py` clean (all examples pass)

## 3. Verify

- [x] 3.1 `swift test` (Swift matcher cross-check on every example); `python3 tools/test_pipeline.py`
- [ ] 3.2 Lens UI test still green; `openspec validate grammar-lens-coverage --strict`
