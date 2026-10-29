# Sentry: подключение (шаги владельца)

Код уже готов (изменение `crash-reporting`). Сборка без DSN работает как раньше: Sentry
просто не запускается. Ниже то, что делается в браузере и в настройках репозитория.

Решения владельца (2026-10-28): только сбои и ошибки; регион EU (Франкфурт); отчёты
включены всегда, без отдельного переключателя.

## Что нужно получить в итоге

| Что | Куда | Секрет? |
|---|---|---|
| DSN проекта | GitHub secret `SENTRY_DSN`; локально — строка в `Lorito/Config.local.xcconfig` | нет, но в git не коммитим |
| Organization auth token | GitHub secret `SENTRY_AUTH_TOKEN` | **да** |
| Slug организации | GitHub variable `SENTRY_ORG_SLUG` (по умолчанию `lorito`) | нет |
| Slug проекта | GitHub variable `SENTRY_PROJECT_SLUG` (по умолчанию `lorito`) | нет |

## Шаги

1. **Организация в EU.** На https://sentry.io/signup/ зарегистрируйтесь (или войдите).
   При создании организации в поле *Data Storage Location* выберите
   **European Union (EU)**. Регион потом не меняется. Slug организации — например,
   `lorito`. План — Developer (бесплатный).
2. **Проект.** *Projects → Create Project* → платформа **Apple iOS**, алерты —
   «Alert me on high priority issues», имя (slug) `lorito`. Экран с инструкцией по
   установке SDK пропустите: код уже готов.
3. **DSN.** *Project Settings → Client Keys (DSN)* → скопируйте DSN вида
   `https://<key>@o<число>.ingest.de.sentry.io/<число>`.
   Проверьте, что в адресе есть `.de.` — значит, данные в EU.
4. **Приватность проекта.** *Project Settings → Security & Privacy*:
   - **Data Scrubber** — включён;
   - **Use Default Scrubbers** — включён;
   - **Prevent Storing of IP Addresses** — включить (политика конфиденциальности
     обещает, что IP не сохраняется).

   Те же три переключателя есть на уровне организации
   (*Organization Settings → Security & Privacy*); включите их и там.
5. **Session Replay и Performance.** Ничего не включайте: SDK настроен без трейсинга и
   без записи сессий.
6. **Защита квоты.** *Organization Settings → Spike Protection* — включена для
   `lorito`.
   *Project Settings → Inbound Filters* — включите «Filter out events coming from
   localhost» и «Filter out known web crawlers»; остальное по умолчанию.
7. **Auth token для dSYM.** *Organization Settings → Auth Tokens* (**Organization
   Tokens**) → *Create New Token*, имя `lorito-ci`. Токен показывается один раз:
   сразу вставьте его в GitHub (шаг 8). Никуда больше его не копируйте, в чат тоже.
8. **GitHub** (`Settings → Secrets and variables → Actions`):
   - Secrets: `SENTRY_DSN` (DSN целиком, с `https://` — workflow сам отрежет схему),
     `SENTRY_AUTH_TOKEN`.
   - Variables: `SENTRY_ORG_SLUG`, `SENTRY_PROJECT_SLUG`.
9. **Локально** (по желанию, для тестового события): в
   `Lorito/Config.local.xcconfig` добавьте строку **без** `https://`:
   `SENTRY_DSN = <key>@o<число>.ingest.de.sentry.io/<число>`.
   Запустите Debug-сборку с аргументом `-crash-reporting`. Событие появится в
   *Issues* с `environment: debug`. Release-сборки шлют в `production`.
10. **App Store Connect → App Privacy** (это делается только в веб-интерфейсе) —
    добавьте типы данных:
    - **Diagnostics → Crash Data**;
    - **Diagnostics → Performance Data** (зависания);
    - **Diagnostics → Other Diagnostic Data**.

    Для каждого: цель — **App Functionality**, **Not linked to the user**,
    **Not used for tracking**. Имеющиеся ответы про Usage Data (TelemetryDeck)
    не меняются.
11. Опубликуйте обновлённую `docs/privacy.html` (раздел «Отчёты о сбоях») вместе с
    первым релизом, где включён Sentry.

## Промпт для агента в браузере

Скопируйте целиком в агента, работающего в вашем браузере (Claude in Chrome и т. п.).
Агент останавливается перед шагами, где нужны пароль, оплата или секрет.

```
Задача: настроить Sentry для iOS-приложения Lorito. Работай в моём браузере, шаг за
шагом, и после каждого шага коротко пиши, что сделал.

Правила:
- Пароли, коды 2FA и платёжные данные не вводи — остановись и попроси меня.
- Не выбирай платные планы и пробные периоды; если Sentry предлагает trial —
  откажись или спроси меня.
- Auth token НЕ копируй в чат и никуда, кроме поля секрета GitHub в шаге 7.
  Если не можешь вставить его сам, остановись: я скопирую сам.
- Ничего не удаляй и не меняй в других проектах или организациях Sentry и
  в других репозиториях GitHub.
- Если интерфейс отличается от описания, найди ближайший эквивалент; если не
  уверен — спроси.

1. Открой https://sentry.io. Если у меня уже есть организация Sentry, покажи её
   название и регион хранения данных (Organization Settings → General) и спроси,
   использовать ли её. Иначе создай организацию: Data Storage Location =
   European Union (EU), slug "lorito" (если занят — "lorito-app"), бесплатный
   план Developer.
2. Создай проект: платформа Apple iOS, alert "Alert me on high priority issues",
   имя/slug "lorito". Инструкцию по установке SDK пропусти.
3. Project Settings → Client Keys (DSN): скопируй DSN и покажи мне. Проверь, что
   хост содержит ".ingest.de.sentry.io".
4. Project Settings → Security & Privacy: включи Data Scrubber, Use Default
   Scrubbers, Prevent Storing of IP Addresses. Сделай то же в Organization
   Settings → Security & Privacy.
5. Organization Settings → Spike Protection: включено для lorito.
   Project Settings → Inbound Filters: включи фильтры localhost и web crawlers.
   Performance/Tracing и Session Replay не включай.
6. Organization Settings → Auth Tokens → Organization Tokens → Create New Token,
   имя "lorito-ci". Не копируй токен в чат.
7. Открой https://github.com/<OWNER>/<REPO>/settings/secrets/actions
   (спроси у меня owner/repo, если не знаешь). Создай secrets:
   SENTRY_AUTH_TOKEN = токен из шага 6; SENTRY_DSN = DSN из шага 3.
   На вкладке Variables создай SENTRY_ORG_SLUG = slug организации и
   SENTRY_PROJECT_SLUG = lorito.
8. Итог: напиши slug организации, slug проекта, DSN и регион. Подтверди, что
   оба секрета и обе переменные созданы в GitHub. Токен не повторяй.
```

## После настройки

- Пришлите мне DSN: я пропишу его локально и проверю тестовое событие из
  Debug-сборки. Токен не присылайте.
- Первый релиз с Sentry: убедитесь, что в логе `fastlane build` есть загрузка dSYM,
  а не «skipping the Sentry dSYM upload».
