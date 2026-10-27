# Промпт для Claude Code: реализация редизайна Plumaje

Запуск: `cd ~/src/lorito && git checkout redesign-plumaje && claude`, затем вставить текст ниже.

---

Ты реализуешь редизайн Lorito «Plumaje» в ветке `redesign-plumaje`. Всё уже спроектировано — твоя задача реализовать, не перепридумывать.

## Источники истины (прочитай перед началом)

1. `CLAUDE.md` — архитектура, команды, конвенции (только семантические токены, Domain без SwiftUI/SwiftData).
2. `design/README.md`, `design/brand/tokens.json` — токены, шрифты, иконка. Значения цветов брать ТОЛЬКО отсюда.
3. `design/mockups/*.dc.html` — макеты экранов (HTML с inline-стилями; читай как референс по раскладке, отступам, иерархии).
4. Пять OpenSpec-изменений в `openspec/changes/`, в каждом `proposal.md`, `design.md`, `tasks.md`, `specs/**`.
5. `graphify-out/GRAPH_REPORT.md` — карта кода.

Ассеты (шрифты в `Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts/`, иконка в `AppIcon.appiconset`) уже в репо — не перегенерируй и не скачивай заново.

## Порядок — строго последовательно

1. `plumaje-design-system`
2. `recall-first-study`
3. `progress-insights`
4. `ipad-plumaje-layouts`
5. `home-screen-widgets`

Для каждого изменения:

1. `/opsx:apply <change>` — иди по `tasks.md` сверху вниз, отмечай `- [x]` по мере выполнения.
2. TDD там, где tasks говорит «failing tests»: сначала тест, убедиться что он красный, потом реализация.
3. После каждой секции tasks: `cd Packages/LoritoKit && swift test`.
4. В конце изменения:
   - `swift test` — зелёный, без новых предупреждений;
   - `xcodegen generate` (если менялся `project.yml`) и `xcodebuild -project Lorito.xcodeproj -scheme Lorito -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`;
   - UI-тесты из tasks на iPhone 17 Pro, а для `ipad-plumaje-layouts` — ещё на iPad Pro 13";
   - `rg 'Color\(hex' Packages/LoritoKit/Sources --glob '!**/Tokens/**'` — пусто;
   - `openspec validate <change> --strict`;
   - `graphify update .`;
   - отдельный коммит `feat(<change>): …` (Conventional Commits, как в истории репо);
   - `/opsx:archive <change>`, коммит `chore(openspec): archive <change>`.
5. Коротко отчитайся: что сделано, что осталось ручной проверкой (пункты tasks про устройство), и переходи к следующему изменению.

## Правила

- Не меняй поведение сверх спек. Если спека и макет расходятся — права спека; если спека неясна — остановись и спроси, не угадывай.
- Цифры в макетах (серия 13, 412 повторений и т. п.) — демо-данные. В коде всё считается из реальных данных.
- Иконки — SF Symbols, ближайшие по смыслу к контурам из макетов; эмодзи в UI не использовать.
- Испанский текст — только через `SpanishText` / `LoritoFont.spanish*`; у Instrument Serif нет кириллицы.
- Dynamic Type: каждый стиль через `Font.custom(_:size:relativeTo:)`; проверить AX5 на Today и в сессии.
- Не трогай `secrets/`, `fastlane/` (кроме задач про скриншоты), CloudKit-схему и модели SwiftData — схема данных в этих изменениях не меняется.
- `home-screen-widgets` требует App Group и нового App ID в Developer Portal. Код и `project.yml` подготовь, но регистрацию в портале и подпись оставь мне: перечисли точные шаги и остановись.
- `recall-first-study`, задача 1.5 (поле `recall` для 59 карточек A1–A2): сгенерируй черновики через `tools/enrich.py --recall`, закоммить отдельно и пометь в отчёте «нужна вычитка».
- Не пушь и не открывай PR — это я сделаю сам после ревью.

## Критерий готовности

Все пять изменений в `openspec/changes/archive/`, спеки в `openspec/specs/` обновлены, `swift test` и сборка зелёные, в отчёте — список пунктов для ручной проверки на устройстве.
