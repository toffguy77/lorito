## Why

Relocants meet Spanish in the wild — a letter from the bank, a rental contract, a
shop sign — and want to know "what rule is this?". Today Lorito can only be studied
top-down through the plan and catalog. Grammar Lens turns any Spanish text into an
entry point to the 159 cards: it highlights recognisable constructions and links
each one to the card that explains it in Russian. It is the audit's most
differentiating killer feature: it needs our authored rule content, which
English-first competitors do not have.

## What Changes

- «Что здесь за правило?» entry: paste text, share text into Lorito (share sheet /
  Action extension), or capture text with Live Text from the camera or a photo.
- **On-device analysis only:** NaturalLanguage sentence/word tokenization plus a
  compiled lemma table shipped in content, followed by a deterministic rule
  matcher. Rules use only surface forms and lemmas (no lexical-class predicates), so
  the pipeline validator and the app evaluate them identically.
- **Detection rules as content:** each rule (e.g. ser vs estar, subjuntivo after
  trigger phrases, pretérito vs imperfecto time markers, gender exceptions like
  *el problema* / *la mano*) maps a pattern to one or more card IDs; authored in
  `content/lens/`, validated and compiled by the pipeline, with positive and
  negative test sentences.
- **Precision over recall:** a span is highlighted only when a rule matches with
  its required context; unknown text is shown plain, never guessed.
- Each highlight opens the card; «Добавить в повторение» marks a card the user has
  not started as user-requested, so it enters today's new items within the shared
  daily budget ahead of order-based picks; an already scheduled card is not moved
  (its next due date is shown instead).
- Lens is free (not part of Lorito Pro).

## Capabilities

### New Capabilities
- `grammar-lens`: input sources, on-device analysis, rule matching, highlighting,
  linking to cards and adding them to review, rule content format.

### Modified Capabilities
- `daily-plan`: user-requested new items take priority within the daily new budget.
- `product-analytics`: adds Grammar Lens events.

## Impact

- **Content**: `content/lens/*.md` rule files; `tools/validate.py` runs each rule's
  example sentences through a Python reference matcher; `compile.py` emits
  `lens.json`.
- **Domain**: `LensRule`, `LensToken`, `LensMatcher` (pure, works on tokens, testable
  with fixture token streams without NaturalLanguage); `requestedItems` input to the
  daily planner.
- **Persistence**: `requestedAt` on the item's settings/review record per
  `cloudkit-schema-release` (optional, synced).
- **Features**: `LensTokenizer` adapter over `NLTagger`; input screens (paste, camera
  via VisionKit), results view, share/Action extension target.
- **project.yml**: Action extension target; `NSCameraUsageDescription`.
- **Depends on**: `learning-platform-foundation` (review items, combined new-item
  budget, `CardBodyParser` in Domain), `cloudkit-schema-release`, `spanish-audio`
  (optional "listen" on a highlight), `product-analytics`. Base: `plumaje-design-system`,
  `recall-first-study`.
