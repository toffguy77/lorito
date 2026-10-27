# Промпт для Claude Code: реализация роадмапа

Запуск: `cd ~/src/lorito && claude`, затем вставить текст ниже. Предполагается, что изменения из `redesign-plumaje` (progress-insights, ipad-plumaje-layouts, home-screen-widgets) либо уже реализованы и заархивированы, либо идут параллельно — шаг 0 это учитывает.

---

Ты реализуешь роадмап Lorito по OpenSpec. Всё спроектировано и провалидировано — реализуй, не перепридумывай. Работай автономно, но останавливайся в точках, помеченных **STOP**.

## Источники истины (прочитай до начала)

1. `CLAUDE.md` — архитектура и конвенции (Domain чистый, только семантические токены, Python-пайплайн на stdlib).
2. `design/ROADMAP.md` — порядок, зависимости, решения владельца. Решения владельца не пересматривай.
3. Каждое изменение в `openspec/changes/<name>/`: `proposal.md`, `design.md`, `tasks.md`, `specs/**`. Спека важнее design.md; design.md важнее твоих догадок.
4. `graphify-out/GRAPH_REPORT.md` — карта кода; после изменений кода — `graphify update .`.
5. `design/README.md`, `design/brand/tokens.json`, `design/mockups/*.dc.html` — визуальный язык Plumaje для новых экранов.

## Шаг 0. Хотфикс в прод (отдельно от роадмапа)

В выпущенной 1.5.0 лимит новых карточек в день не работает: после оценки новой карточки `TodayModel.refresh()` пересчитывает план, и `DailyPlanner.selectNew` выдаёт следующую новую — без ограничения. Подробности — `openspec/changes/learning-platform-foundation/design.md` и требование «New-card count limit» в его `specs/daily-plan/spec.md`.

1. `git checkout main && git checkout -b hotfix/daily-new-card-limit`.
2. Только учёт «введено сегодня» для карточек (задачи 3.1–3.3 и 3.5 foundation, без бюджета, видов и локального дня). TDD: сначала тест, воспроизводящий баг.
3. `swift test`, сборка, UI-тест «закончил новую карточку → Today показывает all-done».
4. Подними версию до 1.5.1 (`project.yml`: `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` +1), `xcodegen generate`, коммит `fix(daily-plan): enforce daily new-card limit across replans`.
5. **STOP** — отчитайся; релиз хотфикса делаю я.

## Шаг 1. Подготовка ветки

1. `git checkout openspec-roadmap`, затем `git merge redesign-plumaje` (вливаем уже сделанное). Конфликты в `openspec/` решай так: архивы и спеки из `redesign-plumaje` побеждают; изменения из `openspec-roadmap` (включая исправленный `streak-reminders`) накладываются поверх.
2. Влей и хотфикс: `git merge hotfix/daily-new-card-limit`.
3. `openspec validate --all --strict` (или по каждому изменению) — всё должно быть valid, без «Archive would refuse». Если что-то сломалось после мержа — почини дельту, сохранив смысл, и упомяни в отчёте.
4. Если `streak-reminders` реализован, но не заархивирован — `/opsx:archive streak-reminders`.

## Шаг 2. Реализация по фазам

Строго по порядку из `design/ROADMAP.md`, по одному изменению:

- Фаза 0: `learning-platform-foundation` → `cloudkit-schema-release`
- Фаза 1: `product-analytics` → `spanish-audio` → `fsrs-scheduler` → `aso-grammar-positioning` (этап 1)
- Фаза 2: `placement-test-and-first-session` → `study-goal` → `streak-protection` → `personal-traps` → `conjugation-trainer` → `weekly-recap-and-milestones`
- Фаза 3: `lorito-pro` → `listening-and-pronunciation` → `exam-path-dele-ccse` → `vocabulary-decks` → `regional-variants` → `aso-grammar-positioning` (этап 2)
- P2: `grammar-lens` → `study-buddy`

Для каждого изменения:

1. `/opsx:apply <change>`; иди по `tasks.md` сверху вниз, отмечай `- [x]` сразу после выполнения.
2. TDD везде, где tasks говорит «failing tests»: тест → убедиться, что он красный → реализация.
3. После каждой секции: `cd Packages/LoritoKit && swift test`; при изменениях контента — `python3 tools/test_pipeline.py` и `python3 tools/compile.py`.
4. Синхронизируемые данные — только по конвенции `cloudkit-schema-release`: опциональное/дефолтное поле, маппинг в обе стороны в `SwiftDataUserDataStore`, round-trip тест, обновлённый `cloudkit/schema.ckdb`.
5. Конец изменения:
   - `swift test` зелёный, без новых предупреждений;
   - `xcodegen generate` (если менялся `project.yml`) + `xcodebuild -project Lorito.xcodeproj -scheme Lorito -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`;
   - UI-тесты из tasks (iPhone 17 Pro; для экранов с iPad-раскладкой — ещё iPad Pro 13");
   - `rg 'Color\(hex' Packages/LoritoKit/Sources --glob '!**/Tokens/**'` — пусто;
   - `openspec validate <change> --strict`;
   - `graphify update .`;
   - коммит `feat(<change>): …` (Conventional Commits, как в истории);
   - `/opsx:archive <change>` + коммит `chore(openspec): archive <change>`.
6. Короткий отчёт (что сделано, что осталось ручной проверкой на устройстве) — и дальше.
7. **STOP после каждой фазы**: сводка фазы, список ручных проверок и шагов владельца. Следующую фазу начинаешь только после моего «дальше».

## Шаги владельца — не делай сам, подготовь и остановись

Где tasks требуют действий вне репозитория, подготовь всё, что можно (код, конфиги, точные инструкции по шагам), отметь задачу как `- [ ] … (owner)` и перечисли её в отчёте:

- CloudKit Console → «Deploy Schema Changes» перед релизом с новыми синхронизируемыми полями (гейт `tools/cloudkit_schema_check.sh` должен проходить).
- App Store Connect: этапы в `lorito-pro` (соглашения, налоги, банк вне РФ, группа подписок, продукты, цены, семейный доступ, пробный период, песочница) и в `aso-grammar-positioning` (загрузка метаданных, проверка длины ключевых слов). API-ключ есть в `secrets/asc.env` — им можно читать/проверять, но ничего не создавай и не отправляй в App Store Connect без моего явного «да».
- Developer Portal: App Group и новые App ID для `home-screen-widgets`, push-entitlement для `study-buddy`.
- Импорт банка CCSE из материалов Instituto Cervantes: импортёр, валидатор и атрибуция — твои; сам файл-источник положу я, если не найдёшь его в открытом доступе на cervantes.es.

## Правила

- Решения владельца из `design/ROADMAP.md` не пересматривай (Pro = только экзамены; CCSE из Cervantes можно; FrequencyWords — CC BY-SA 4.0 с `LICENSE` в `content/vocabulary/` и `content/conjugation/`; название «Lorito: испанский язык»).
- Не меняй поведение сверх спек. Спека неясна или противоречит коду — остановись и спроси, не угадывай. Если нашёл баг вне текущего изменения — запиши в отчёт, не чини молча.
- Контент на испанском и объяснения на русском, которые генерируешь (recall-подсказки, колоды, глаголы, вопросы), коммить отдельно с пометкой «нужна вычитка».
- Цифры в макетах — демо-данные; в коде всё из реальных данных.
- Иконки — SF Symbols; эмодзи в UI нет; испанский — только через `SpanishText` / Spanish-стили; русские числительные — через `RussianPlural`.
- Не трогай `secrets/` и подпись. Не пушь, не открывай PR, не выпускай релизы.

## Критерий готовности

Все изменения из `design/ROADMAP.md` в `openspec/changes/archive/`, спеки в `openspec/specs/` обновлены, `swift test`, пайплайн и сборка зелёные. В финальном отчёте: список ручных проверок, шагов владельца и найденных по пути проблем.
