## 1. Domain (TDD)

- [x] 1.1 Failing tests: `CatalogCardID` accepts `B1-03`, rejects `word:casa`, `conj:ser:…`, `A1-7`, free text; `lens_card_requested` parameters are `["card": "B1-03"]`; the record round-trips through the analytics queue encoding
- [x] 1.2 `CatalogCardID` value (failable init on the card-id pattern) and `case lensCardRequested(card: CatalogCardID)`; update the taxonomy doc comment

## 2. Features (TDD)

- [x] 2.1 Failing test: requesting `A1-01` from Lens records `.lensCardRequested(card: A1-01)`
- [x] 2.2 `LensModel.request` sends the id (skips the event if the id is not a catalog id)

## 3. Verify

- [x] 3.1 `swift test`; `openspec validate lens-card-analytics-id --strict`
