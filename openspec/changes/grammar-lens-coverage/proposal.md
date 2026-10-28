## Why

Grammar Lens ships 26 rules linked to 22 of 159 cards. Most texts a learner pastes
(a letter, an article) contain constructions Lorito teaches — comparatives,
the future, *se* passives, *lo que*, *aunque*, connectors — that are not
highlighted, so Lens looks empty and the "what rule is this?" promise breaks. There
is also no record of which cards were deliberately left without a rule, so gaps
can't be told from decisions.

## What Changes

- **Coverage map:** `content/lens/coverage.json` lists every card that has no rule,
  each with a reason (pronunciation, spelling, lexis, style — nothing a surface
  pattern can find). Validation fails when a card is neither linked by a rule nor
  listed there, or is both. Every new card is then a conscious decision.
- **~50 new rules** for the A1–B2 grammar cards that have a reliable surface
  signature (accented question words, demonstratives, comparatives, futuro and
  condicional, indefinido without present-tense look-alikes, *se* passive and *se*
  accidental, perífrasis, prepositional verbs, connectors, relatives *el cual* /
  *cuyo*, *lo + adj*, perfect and pluperfect subjunctive, *de haber* + participle,
  regrets, causal and concessive conjunctions), plus C1 rules for *futuro de
  subjuntivo*, *queísmo/dequeísmo*, *al + infinitivo*, *una vez + participio*,
  *el hecho de que*. Existing rules also link A2-06 (perfecto vs indefinido
  markers) and A2-08 (*ir a* + infinitive).
- **Set composition** in `sets.json` (pipeline only — the app receives expanded
  sets): `tenses` (union of tenses), `exclude_tenses` (drop look-alikes, e.g.
  *hablamos* from the indefinido set) and `inflect` for participles
  (*cerrada, cerrados*).
- Precision stays first: every rule keeps ≥ 3 positive / ≥ 2 negative examples, and
  the app/pipeline cross-check covers all examples.
- Generated content — separate commit, «нужна вычитка».

## Capabilities

### Modified Capabilities
- `grammar-lens`: coverage map requirement; set composition in rule validation.

## Impact

- `content/lens/{rules/*.json,sets.json,lemmas.tsv,coverage.json}`, compiled `lens.json`.
- `tools/lens.py`, `tools/test_pipeline.py`, `content/schema.md`.
- No app code change: the matcher and the expanded-set format are unchanged; the
  Swift cross-check test verifies parity on all new examples.
