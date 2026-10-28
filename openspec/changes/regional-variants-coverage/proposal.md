## Why

`regional-variants` shipped the markup and the rendering, but little content uses
it: variant blocks in 5 cards and inline alternatives in 3. Eighteen grammar cards
still show a *vosotros* row in their conjugation tables with no word for a
Latin-American or Rioplatense learner that the row is Spain-only, or what *vos*
looks like in that tense. One example used *coger* («cogí el coche»), which is
vulgar in much of Latin America. Nothing stops new cards from repeating this.

## What Changes

- **Plan:** make coverage a validated property of content, then fill it.
- **Pipeline checks** (`tools/variants.py`): a card whose table has a *vosotros*
  row or column (outside a Spain-only block) must carry notes for `am` and `rio`;
  an example sentence with *coger* must sit in a Spain block or an inline
  alternative. C1-18 (the card that compares the variants) is exempt.
- **Content:** `am` and `rio` notes for the 18 cards with *vosotros* tables:
  - `am` notes give the *ustedes* form;
  - `rio` notes give the *vos* form:
    - the stressed present (*vos tenés*, *vos te llamás*);
    - *tú* forms in the other tenses;
    - norm vs colloquial for the subjunctive and negative imperative (*no hables* / *no hablés*).
- A2-01 notes the Latin-American preference for indefinido.
- B1-13's *cogí el coche* becomes neutral; C1-15's *coger el toro* gets an `am` alternative.
- A1-30 gains a glossary of the 13 most frequent lexical differences as inline
  alternatives (*coche / carro / auto*, *móvil / celular*, *nevera / heladera*…),
  with a warning about *coger*.
- Generated content — separate commit, «нужна вычитка».

## Capabilities

### Modified Capabilities
- `regional-variants`: content coverage requirement enforced by the pipeline.

## Impact

- `tools/variants.py`, `tools/validate.py`, `tools/test_pipeline.py`.
- 20 card files; compiled `content.json`.
- No app code change.
- Not in scope: the vocabulary decks have no per-variant word field. Spain-leaning
  words like *coche* and *ordenador* need a model change in a follow-up.
