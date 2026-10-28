## Why

After `grammar-lens-coverage`, 62 cards stay in the Lens coverage map. Some are
truly invisible in text (pronunciation, register, text genre), but about a dozen
are lexical cards — idioms, proverbs, set phrases, connectors, Latinisms — whose
content is a closed list of expressions the card itself teaches. A surface rule
per expression would find them; writing each one as a separate rule file with
three examples is what kept them out.

## What Changes

- **Phrase-list rules:** a rule file may list `phrases` (`text`, `ru`, `example`)
  instead of a `pattern`. The pipeline expands it into one ordinary rule per phrase
  — a surface step per word, `a|b` alternatives, `~lemma` for a word that inflects
  (`~echar de menos`) — titled with the phrase's Russian meaning, its example as
  the positive example and the list's negatives shared. The app receives ordinary
  rules: no Swift change; the cross-check covers every phrase.
- Validation: at least 3 phrases, each with text, meaning and an example that
  matches; no `pattern` next to `phrases`; the shared negatives must match no
  phrase.
- **Content (generated — нужна вычитка):** phrase lists for the lexical cards whose
  expressions appear in the card body, taken from the card; those cards leave the
  coverage map. Cards that teach a skill, a style or a property of whole texts stay
  in the map with their reasons.

## Capabilities

### Modified Capabilities
- `grammar-lens`: phrase-list rules.

## Impact

- `tools/lens.py`, `tools/test_pipeline.py`, `content/schema.md`.
- `content/lens/rules/*.json`, `content/lens/coverage.json`; compiled lens bundle.
