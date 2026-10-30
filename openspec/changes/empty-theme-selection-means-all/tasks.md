## 1. Fix

- [x] 1.1 Failing test: a model loaded from settings with a level and no themes has every in-scope theme selected and is studyable (init and `reload()`)
- [x] 1.2 Implement in `ScopeSelectionModel`

## 2. Verify

- [x] 2.1 `swift test`; screenshot UI flow (setup re-run on the demo store) on iPhone and iPad; `openspec validate empty-theme-selection-means-all --strict`
