# Tasks

## 1. Domain: подбор упражнений (TDD)

- [x] 1.1 Failing tests `DomainTests/PracticeSelectorTests.swift`: допустимы только упражнения карточек со статусом ≠ new (suspended допустима); unstudied карточка не попадает ни в один режим
- [x] 1.2 Failing tests: «Смешанная» — лимит 20, сначала никогда не решённые, затем самые давние; соседние упражнения одной карточки разведены, когда это возможно; детерминизм при одинаковом seed
- [x] 1.3 Failing tests: «Слабые места» — последняя попытка по exercise id неверна, порядок по дате промаха (свежие первыми), лимит 20; после верного ответа упражнение выпадает
- [x] 1.4 Failing tests: «По теме» — все допустимые упражнения темы в порядке карточек; «По уровню» — лимит 20, только этот уровень
- [x] 1.5 Failing tests: `availability` возвращает «доступно X из Y» для темы, уровня, всего каталога и «Слабых мест»
- [x] 1.6 Implement `Domain/Practice/PracticeSelector.swift` (+ `PracticeMode`) без импортов SwiftUI/SwiftData; verify `swift test --filter PracticeSelectorTests` проходит

## 2. Domain: оценка свободной практики (TDD)

- [x] 2.1 Failing tests в `ExercisePracticeServiceTests`: в `.free` верный auto-ответ пишет попытку `correct: true`, не пишет `StudyEvent` и не меняет `ReviewState`; самооценка Трудно/Хорошо/Легко — то же
- [x] 2.2 Failing tests: в `.free` неверный ответ и самооценка Опять применяют `.again` через `GradingService` и пишут событие; повторный промах в тот же день пишет событие без изменения состояния; `speak` в `.free` никогда не меняет состояние
- [x] 2.3 Failing test: `.reader` ведёт себя как раньше (существующие тесты не меняются)
- [x] 2.4 Implement `PracticeGrading` в `ExercisePracticeService`; параметр `correct` у `recordAttemptOnly`; verify `swift test --filter ExercisePracticeServiceTests`

## 3. Domain: Pro и аналитика (TDD)

- [x] 3.1 Failing tests `EntitlementResolverTests`: покупка даёт `[.examPath, .practice]`, без покупки — пусто
- [x] 3.2 Add `ProFeature.practice`, `PaywallEntry.practice`; verify tests pass
- [x] 3.3 Failing test: `practiceStarted(mode:count:)` имеет стабильное имя и payload только из `mode` и `count`; `PracticeModeName` — закрытый enum
- [x] 3.4 Implement the analytics case; verify `swift test --filter Analytics`

## 4. Features: сессия и модель практики

- [x] 4.1 `ExerciseSessionModel` принимает `grading: PracticeGrading = .reader` и считает верные ответы; FeaturesTests: свободная сессия не меняет `ReviewState` при верном ответе; вызов из ридера не изменился
- [x] 4.2 `PracticeHubModel` (store, catalog, purchases, analytics): счётчики режимов, `isUnlocked` (`!salesEnabled || isEntitled(.practice)`), `makeSession(mode:)` → сессия или пустое состояние с причиной (нет изученных / нет ошибок / всё отфильтровано аудио); пишет `practiceStarted`. FeaturesTests покрывают пустые состояния и гейт при `salesEnabled: true`
- [x] 4.3 `SessionCompleteView` в свободной практике показывает «Верно X из N»; verify in FeaturesTests или превью

## 5. Features: точки входа

- [x] 5.1 `PracticeHubView` (лист с «Смешанная», «Слабые места», «доступно X из Y», пустые состояния, сноска про Каталог, замок и пейвол `.practice` при необходимости) — только семантические токены, `SpanishText` не нужен; verify `rg 'Color\(hex' Packages/LoritoKit/Sources --glob '!**/Tokens/**'` пуст
- [x] 5.2 Строка «Практика» на «Сегодня» (`today.practice`) между экзаменами и спряжениями, compact и regular; подпись «Упражнения по изученным карточкам»
- [x] 5.3 Каталог: «Практика по теме» в списке карточек темы (`catalog.practice.theme`) и «Практика по уровню» рядом с `examsRow` (`catalog.practice.level`), iPhone и iPad
- [x] 5.4 Пейвол: строка про свободную практику в списке функций Pro (видна только при включённых продажах)
- [x] 5.5 Проверить AX5 на «Сегодня» и в листе практики (длинные подписи переносятся, `.loritoTitleFit()` на заголовке)

## 6. UI-тесты

- [x] 6.1 `PracticeHubUITests`: свежий пользователь → «Практика» → «Смешанная» показывает пустое состояние (алерт «Пока нечего тренировать»)
- [x] 6.2 С изученной карточкой (сид `-lorito-seed-conjugation`, A2-07): «Смешанная» показывает «доступно 5 из …» и запускает сессию только с упражнениями этой карточки; закрытие сессии работает
- [x] 6.3 iPad: «Практика по уровню» из сайдбара Каталога запускает сессию; verify на iPhone 17 Pro и iPad Pro 13 (по одному прогону за раз)

## 7. Интеграция

- [x] 7.1 `swift test` в `Packages/LoritoKit` зелёный; `xcodebuild … build` для iPhone 17 Pro проходит
- [ ] 7.2 `openspec validate practice-hub --strict` проходит; `graphify update .` выполнен

## 8. Выпуск (2.0.1)

- [x] 8.1 Версия 2.0.1 (build 17) в `project.yml`
- [ ] 8.2 Архив и IPA (`fastlane build` на Mac), загрузка в TestFlight (`fastlane upload`); verify: билд 17 в ASC `VALID`
- [ ] 8.3 После выхода 2.0 (2026-11-24): «Что нового» 2.0.1 с практикой, версия 2.0.1 с билдом 17 отправлена на ревью вместе с задачей 5.3 `store-screenshots-2-0-1`
