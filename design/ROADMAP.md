# Lorito — роадмап OpenSpec-изменений

Источник: продуктовый аудит (https://claude.ai/artifact/WtPw47GCiXwhVZBtVMqfEE), 27.10.2026.
Все изменения в `openspec/changes/` проходят `openspec validate --strict`. Ни одно требование не меняется двумя изменениями сразу, поэтому конфликтов при архивации нет; порядок задают только зависимости ниже.

## Уже в работе (ветка `redesign-plumaje`)

| Изменение | Статус |
|---|---|
| `plumaje-design-system` | в архиве |
| `recall-first-study` | в архиве |
| `progress-insights` | реализуется |
| `ipad-plumaje-layouts` | ждёт |
| `home-screen-widgets` | ждёт |
| `streak-reminders` | реализовано, не заархивировано (спека исправлена в этой ветке) |

## Фаза 0 — Платформа (до всего остального)

| # | Изменение | Что даёт | Задач |
|---|---|---|---|
| 0.1 | `learning-platform-foundation` | Чинит баг «бесконечные новые карточки за день»; виды элементов (`conj:`, `word:`, `ccse:`); общий дневной бюджет; локальный учебный день вместо UTC; память обновляется только первой оценкой за день; «Опять» возвращается в конце сессии; единые жесты на испанском тексте; `CardBodyParser` → Domain | 24 |
| 0.2 | `cloudkit-schema-release` | Правило для синхронизируемых полей, схема CloudKit в git, проверка перед релизом | 11 |

## Фаза 1 — Фундамент (ноябрь–декабрь 2026)

Ворота: есть базовые D1 / D7 / D30.

| # | Изменение | Задач | Зависит от |
|---|---|---|---|
| 1 | `product-analytics` | 19 | foundation |
| 2 | `spanish-audio` | 16 | foundation, plumaje |
| 3 | `fsrs-scheduler` | 18 | foundation, cloudkit-schema-release |
| 4 | `aso-grammar-positioning` | 22 | plumaje, recall-first; этап 2 — `exam-path-dele-ccse`; раскрытие покупок — `lorito-pro` |

## Фаза 2 — Привычка (январь–февраль 2027)

Ворота: растёт число дней учёбы в неделю.

| # | Изменение | Задач | Зависит от |
|---|---|---|---|
| 5 | `placement-test-and-first-session` | 20 | foundation, `streak-reminders` |
| 6 | `study-goal` | 16 | foundation, cloudkit-schema-release |
| 7 | `streak-protection` | 18 | foundation, `streak-reminders` |
| 8 | `personal-traps` | 17 | foundation, recall-first |
| 9 | `conjugation-trainer` | 25 | foundation, `spanish-audio` (желательно) |
| 10 | `weekly-recap-and-milestones` | 18 | `progress-insights`, `personal-traps` (желательно) |

## Фаза 3 — Экзамен и деньги (март–апрель 2027)

Ворота: конверсия в Pro измерена.

| # | Изменение | Задач | Зависит от |
|---|---|---|---|
| 11 | `lorito-pro` | 31 | `product-analytics`; этап App Store Connect внутри |
| 12 | `listening-and-pronunciation` | 21 | `spanish-audio` |
| 13 | `exam-path-dele-ccse` | 30 | `spanish-audio`, `study-goal`, `lorito-pro`, `listening-and-pronunciation` |
| 14 | `vocabulary-decks` | 25 | foundation, `spanish-audio` |
| 15 | `regional-variants` | 22 | `spanish-audio`, `conjugation-trainer`, `listening-and-pronunciation` |

## Позже (P2)

| # | Изменение | Задач | Зависит от |
|---|---|---|---|
| 16 | `grammar-lens` | 20 | foundation, `product-analytics` |
| 17 | `study-buddy` | 22 | `cloudkit-sync`, `progress-insights`, `streak-protection` |

## Решения владельца (27.10.2026)

- **Pro = только экзамены** (DELE A2 + CCSE сверх бесплатного превью). Тренажёр спряжений, региональные варианты, «линза» — бесплатно.
- **CCSE:** материалы Instituto Cervantes использовать можно — официальный банк вопросов импортируется с указанием источника и редакции.
- **FrequencyWords:** лицензия контента CC BY-SA 4.0 (код — MIT) подтверждена по README репозитория. `content/vocabulary/` и `content/conjugation/` считаются производными и публикуются под CC BY-SA 4.0 с собственным `LICENSE`; атрибуция — на экране «О приложении». Связываться с автором не нужно.
- **Название:** «Lorito: испанский язык», подзаголовок «Грамматика по-русски, A1–C2». Для Испании и Латинской Америки — локализации es-ES и es-MX с русскими метаданными (русский язык там не индексируется).
- **Ключевые слова:** лимит 100 символов (не байт): текущая строка из 85 символов / 149 байт уже опубликована. Проверка — на этапе загрузки в App Store Connect.

## Решения владельца (29.10.2026)

- **Пока всё бесплатно** (`sales-off`): Paid Apps Agreement для аккаунта сейчас не подписать. Pro не продаётся, экзамены открыты целиком (`Monetization.salesEnabled = false`); код StoreKit и продукты в App Store Connect (Pro Yearly 34,99 €, Pro Lifetime 54,99 €) остаются неотправленными. Если приложение наберёт популярность — продажи через издателя из Европы.

## Что остаётся за владельцем

- **Продажи Pro** — отложены (см. решения 29.10.2026): включаются вместе с издателем из Европы.
- **Деплой схемы CloudKit** — одна кнопка «Deploy Schema Changes» в CloudKit Console перед релизами с новыми полями; может сделать Claude через браузер с подтверждением.

## Вне репозитория

Веб-версия правил для SEO — отдельный проект; контент переиспользуется из `content/`.
