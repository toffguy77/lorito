## 1. Fix

- [x] 1.1 Failing test: `ScopeSelectionModel.reload()` drops an unsaved level and theme change
- [x] 1.2 Implement `reload()`; Settings calls it when the re-run is dismissed
- [x] 1.3 UI test: re-run, pick another level, close; Settings shows the stored level

## 2. Verify

- [x] 2.1 `swift test`; UI tests on iPhone and iPad; `openspec validate setup-close-discards-unsaved-scope --strict`
