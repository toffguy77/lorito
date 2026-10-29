## 1. Switch

- [x] 1.1 Failing tests: with sales off every form starts in full (no preview-only attempt), no paywall; with sales on the existing gating holds
- [x] 1.2 `Monetization.salesEnabled = false` in Domain; `ExamsModel` takes it (default the constant); `isPro` is true while sales are off
- [x] 1.3 `AdaptiveRootView`: purchase service not started and no Pro section in Settings while sales are off

## 2. Tests and metadata

- [x] 2.1 UI tests: Settings has no Pro entry; a second DELE form starts directly (paywall tests skipped while sales are off)
- [x] 2.2 App Store descriptions (ru, es-ES, es-MX): drop the Lorito Pro sentence; exams free

## 3. Verify

- [x] 3.1 `swift test`; UI suite on iPhone and iPad; `openspec validate sales-off --strict`
