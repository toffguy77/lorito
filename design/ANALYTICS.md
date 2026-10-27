# Lorito — аналитика: ответы App Privacy и дашборды

Спека: `openspec/specs/product-analytics/spec.md`. События — закрытый enum
`AnalyticsEvent` (Domain), провайдер — TelemetryDeck (`Lorito/Sources/TelemetryDeckSink.swift`).

## App Store Connect → App Privacy (owner)

Отвечать в том же релизе, где аналитика впервые отправляет события.

| Вопрос | Ответ |
|---|---|
| Do you or your third-party partners collect data from this app? | **Yes** |
| Data type | **Usage Data → Product Interaction** (только это) |
| Linked to the user’s identity? | **No** |
| Used for tracking? | **No** |
| Purposes | **Analytics** (и, по желанию, App Functionality — нет) |

Все остальные типы — не собираются. iCloud-синхронизация (приватная база
CloudKit пользователя) разработчику недоступна и в App Privacy не указывается.
Политика: https://toffguy77.github.io/lorito/privacy.html (`docs/privacy.html`).

## Конфигурация (owner)

1. Создать приложение в TelemetryDeck, взять App ID.
2. GitHub → Settings → Secrets → `TELEMETRYDECK_APP_ID`.
3. Локально (по желанию): `Lorito/Config.local.xcconfig` с
   `TELEMETRYDECK_APP_ID = <id>`; Debug-сборки шлют события только с аргументом
   запуска `-analytics`.
4. Проверить в тестовом режиме TelemetryDeck (Debug + `-analytics`): события
   появляются; авиарежим → занятие → включить сеть → события дошли.

## Определения метрик

- **Активный день** (локальный учебный день): ≥ 1 `itemGraded` или `exerciseAnswered`.
- **D1 / D7 / D30**: доля пользователей, у которых первое событие было в день 0
  и которые активны в день N.
- **North star**: среднее число активных дней за календарную неделю среди
  пользователей, активных в эту неделю.
- **Воронка онбординга**: `onboardingStep(level)` → `onboardingStep(themes)` →
  `onboardingStep(reminders)` → `onboardingCompleted` → первый `sessionCompleted`.

## Запросы дашборда (TelemetryDeck)

| Инсайт | Тип | Фильтр / группировка |
|---|---|---|
| Воронка онбординга | Funnel | шаги: `onboardingStep` (step=level) → (step=themes) → (step=reminders) → `onboardingCompleted` → `sessionCompleted` |
| D1/D7/D30 | Retention | событие возврата: `itemGraded` ∪ `exerciseAnswered`; когорты по первому сигналу |
| Учебных дней в неделю | Breakdown | уникальные дни с `itemGraded`/`exerciseAnswered` на пользователя за неделю → среднее |
| Длина занятия | Distribution | `sessionCompleted.items` |
| Вспомнили с первого раза | Distribution | `sessionCompleted.firstTryPercent` |
| Напоминания | Count | `reminderOpened` / день |
| Серии | Count | `streakExtended.length`, `streakLost.previous` |
| Эксперименты | Breakdown | по `experiment` × `variant` для `sessionCompleted` |
