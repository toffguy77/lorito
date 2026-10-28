## Why

The archived `grammar-lens` delta asked for `lens_card_requested` "with card id",
but the base `product-analytics` taxonomy forbids item identifiers, so the event
shipped without one. The owner decided (2026-10-28) to send the id: which grammar
cards people pull from real-world text is the main signal for authoring more Lens
rules and cards. Bundled grammar card ids (`A1-07`) are public catalog content,
not user data.

## What Changes

- `product-analytics`: the taxonomy allows one kind of identifier — a bundled
  grammar card id matching `^[A-C][12]-\d{2}$` — and only in events whose
  requirement names it. Word, conjugation, CCSE and personal item ids stay
  forbidden.
- `lens_card_requested` carries `card` = the requested card id.
- Domain: a `CatalogCardID` value that can only be built from a valid card id,
  so free text cannot reach the payload.

## Capabilities

### Modified Capabilities
- `product-analytics`: identifier exception for bundled card ids; Grammar Lens
  event payload.

## Impact

- `Domain/Analytics/AnalyticsEvent.swift`, `Features/Lens/LensModel.swift`, tests.
- Privacy disclosures unchanged (still no personal data, not linked to the user).
