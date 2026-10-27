# Lorito — роадмап OpenSpec-изменений

Источник: продуктовый аудит и бенчмаркинг (https://claude.ai/artifact/WtPw47GCiXwhVZBtVMqfEE), 27.10.2026.
Все изменения лежат в `openspec/changes/`, каждое проходит `openspec validate --strict`.
Пересечений по MODIFIED/REMOVED-требованиям между изменениями нет — их можно архивировать в любом порядке, который не нарушает зависимости ниже.

## Уже в работе (ветка `redesign-plumaje`)

| Изменение | Статус |
|---|---|
| `plumaje-design-system` | в архиве |
| `recall-first-study` | в архиве |
| `progress-insights` | реализуется |
| `ipad-plumaje-layouts` | ждёт |
| `home-screen-widgets` | ждёт |

## Фаза 1 — Фундамент (ноябрь–декабрь 2026)

Ворота: есть базовые D1 / D7 / D30.

| # | Изменение | Capability | Задач | Зависит от |
|---|---|---|---|---|
| 1 | `product-analytics` | новая `product-analytics` | 17 | — |
| 2 | `spanish-audio` | новая `spanish-audio` | 14 | plumaje |
| 3 | `fsrs-scheduler` | изменяет `srs-engine` | 16 | — (деплой схемы CloudKit) |
| 4 | `aso-grammar-positioning` | новая `app-store-presence` | 15 | plumaje, recall-first; этап 2 — `exam-path-dele-ccse` |

## Фаза 2 — Привычка (январь–февраль 2027)

Ворота: растёт число дней учёбы в неделю.

| # | Изменение | Capability | Задач | Зависит от |
|---|---|---|---|---|
| 5 | `placement-test-and-first-session` | новая `placement-test`, + `onboarding-and-selection` | 17 | `streak-reminders` (шаг напоминаний остаётся последним) |
| 6 | `study-goal` | новая `study-goal`, + `daily-plan` | 14 | — |
| 7 | `streak-protection` | изменяет `stats-and-streak`, + `reminders` | 16 | `streak-reminders` |
| 8 | `personal-traps` | новая `personal-traps`, изменяет `study-flow` | 14 | recall-first |
| 9 | `conjugation-trainer` | новая `conjugation-trainer`, + `content-*`, `daily-plan` | 24 | `spanish-audio` (желательно) |
| 10 | `weekly-recap-and-milestones` | новая `weekly-recap-and-milestones` | 13 | `progress-insights`, `personal-traps` (желательно) |

## Фаза 3 — Экзамен и деньги (март–апрель 2027)

Ворота: конверсия в Pro измерена.

| # | Изменение | Capability | Задач | Зависит от |
|---|---|---|---|---|
| 11 | `lorito-pro` | новая `monetization` | 19 | `product-analytics`, plumaje |
| 12 | `listening-and-pronunciation` | изменяет `practice-exercises`, `content-*` | 19 | `spanish-audio` |
| 13 | `exam-path-dele-ccse` | новая `exam-path` | 28 | `spanish-audio`, `study-goal`, `lorito-pro`, `listening-and-pronunciation`, `product-analytics` |
| 14 | `vocabulary-decks` | новая `vocabulary`, + `content-*`, `daily-plan` | 22 | `conjugation-trainer`, `spanish-audio` |
| 15 | `regional-variants` | новая `regional-variants`, + `content-*` | 22 | `conjugation-trainer`, `spanish-audio`, `listening-and-pronunciation` |

## Позже (P2)

| # | Изменение | Capability | Задач | Зависит от |
|---|---|---|---|---|
| 16 | `grammar-lens` | новая `grammar-lens` | 18 | recall-first, `product-analytics` |
| 17 | `study-buddy` | новая `study-buddy` | 20 | `cloudkit-sync`, `progress-insights`, `streak-protection` |

## Вне репозитория

Веб-версия правил для SEO — отдельный проект; контент переиспользуется из `content/`.

## Блокирующие решения владельца

- Лицензия на материалы Instituto Cervantes для CCSE (`exam-path-dele-ccse`, гейт-задача).
- Лицензия частотного списка слов (FrequencyWords, CC BY-SA 4.0) для `vocabulary-decks`.
- Цены Pro и Family Sharing — App Store Connect (`lorito-pro`).
- Название в App Store: «Lorito Español» или «Lorito: испанская грамматика» (`aso-grammar-positioning`).
- Хранение IP у провайдера аналитики (`product-analytics`).
- Деплой схемы CloudKit в production перед релизами `fsrs-scheduler`, `vocabulary-decks`, `study-goal`, `personal-traps`.

## Известная проблема в существующем изменении

`streak-reminders` не проходит `openspec validate --strict`: MODIFIED «Skip reminders when nothing is due» теряет сценарий «Nothing due means no notification». Перед `/opsx:archive streak-reminders` этот сценарий нужно вернуть в блок, переписав под новое поведение.
