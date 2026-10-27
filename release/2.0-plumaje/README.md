# Выпуск Lorito 2.0 «Plumaje» — что сделать человеку

Код готов в ветке `redesign-plumaje` (не запушена). Здесь — всё, что
делается вне кода: Developer Portal, подпись, App Store Connect и раздел
Growth & Marketing. Тексты и картинки — в [`marketing.md`](marketing.md) и
[`assets/`](assets/). Пошаговый промпт для ассистента (Claude в браузере) —
[`PROMPT.md`](PROMPT.md).

Как сейчас устроен релиз: push тега `v*` → GitHub Actions `release.yml` →
`fastlane ci_release`: скриншоты на симуляторах «Lorito iPhone» / «Lorito iPad»,
сборка, TestFlight, `deliver` (метаданные из `fastlane/metadata`, скриншоты,
отправка на ревью; выпуск после одобрения — вручную в ASC).

## Порядок и сроки

| Когда | Что | Раздел |
|---|---|---|
| сейчас | Featuring Nomination с датой выхода | [6](#6-featuring-nomination) |
| сейчас | Developer Portal: App Group, App ID виджетов, профили | [1](#1-developer-portal-и-подпись) |
| сейчас | fastlane: профиль расширения; решение по автоматическому выпуску | [1](#1-developer-portal-и-подпись), [2](#2-версия-и-метаданные-в-репозитории) |
| сейчас | Ручная проверка на устройстве | [3](#3-проверка-на-устройстве) |
| день Т−7…Т−3 | ASC: возрастной рейтинг, App Privacy, Accessibility Labels | [4](#4-app-store-connect-перед-отправкой) |
| день Т−7…Т−3 | merge → тег `v2.0.0` → CI отправляет на ревью | [5](#5-выпуск) |
| после одобрения | Asset Library, In-App Events, Custom Product Pages | [7](#7-growth--marketing) |
| +2 недели | Product Page Optimization, второе событие | [7](#7-growth--marketing) |

---

## 1. Developer Portal и подпись

[developer.apple.com → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list), команда `3GWRDGA8B7`.

1. **Identifiers → «+» → App Groups** → `group.com.toffguy.lorito`, описание «Lorito shared».
2. **Identifiers → `com.toffguy.lorito`** → включить **App Groups** → Configure →
   отметить `group.com.toffguy.lorito` → Save. (iCloud/CloudKit и Push не трогать.)
3. **Identifiers → «+» → App IDs → App** → Bundle ID `com.toffguy.lorito.widgets`
   (explicit), описание «Lorito Widgets» → включить **App Groups** →
   `group.com.toffguy.lorito`.
4. **Profiles**: перевыпустить App Store-профиль `com.toffguy.lorito`
   (в старом нет App Group) и создать App Store-профиль для
   `com.toffguy.lorito.widgets` с текущим сертификатом Apple Distribution.
   Lane `build` сам скачивает профиль через `get_provisioning_profile`, но
   существующий профиль без App Group надо сначала удалить/перевыпустить.
5. **fastlane/Fastfile, lane `build`** (сам код — по вашему решению, могу сделать):
   - второй вызов `get_provisioning_profile(app_identifier: "com.toffguy.lorito.widgets", filename: "lorito_widgets_appstore.mobileprovision", …)`;
   - в `export_options.provisioningProfiles` добавить
     `"com.toffguy.lorito.widgets" => <имя профиля расширения>`.
6. Локально: `xcodegen generate`, сборка на своё устройство с подписью —
   убедиться, что расширение подписывается и виджеты видят данные.
7. CloudKit-схема не менялась — в CloudKit Console ничего делать не нужно.

## 2. Версия и метаданные в репозитории

1. `project.yml`: `MARKETING_VERSION` → `2.0.0` **у обоих** таргетов
   (`Lorito` и `LoritoWidgets` — должны совпадать), `CURRENT_PROJECT_VERSION` → `11` (1.5.1 уходит со сборкой 10).
2. `fastlane/metadata/ru/`: заменить `subtitle.txt`, `keywords.txt`,
   `promotional_text.txt`, `description.txt`, `release_notes.txt` и
   `review_information/notes.txt` текстами из `marketing.md` §1.
   В старом описании неверно «прогресс хранится на вашем устройстве» — с 1.3
   есть синхронизация через iCloud.
3. **Выпуск вручную.** В `ci_release` и `submit` стоит `automatic_release: false`:
   после одобрения версия ждёт кнопки «Release This Version» в ASC — выпускать в
   дату из номинации на фичеринг.
4. Скриншоты: CI переснимет их сам. Новый набор: 8 кадров на iPhone 6.9" и
   8 на iPad 13" в альбомной ориентации (локально уже лежат в
   `fastlane/screenshots/ru`). С апреля 2027 понадобятся ещё скриншоты iPhone Duo.
5. Слить `redesign-plumaje` в `main`, запушить.

## 3. Проверка на устройстве

Полный список ручных проверок — в отчёте о реализации; минимум перед релизом:

- иконка: светлая / тёмная / tinted, Settings и Spotlight;
- занятие целиком с VoiceOver и на самом крупном шрифте;
- iPad с клавиатурой: Return (начать), пробел, 1–4, Esc; ⌘-оверлей;
  Split View / Slide Over посреди занятия;
- виджеты (светлый / тёмный / tinted, экран блокировки, StandBy), вопрос в
  виджете, Live Activity за всё занятие, «Поделиться» в итоге занятия;
- **обновление поверх 1.5**: установить 1.5 из App Store, позаниматься,
  поставить 2.0 — прогресс должен остаться (хранилище закреплено за
  контейнером приложения, но это стоит увидеть своими глазами);
- вычитать черновики `recall` для A1–A2 (коммит `92a5d6d`).

## 4. App Store Connect перед отправкой

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Apps → Lorito Español.

1. **App Information → Age Rating**: пройти обновлённую анкету (с июля 2026
   есть вопросы о соцсетевых функциях). Ответы: соцсетей, чатов,
   пользовательского контента, рекламы, веб-доступа нет → 4+.
2. **App Privacy**: остаётся «Data Not Collected». Виджеты, Live Activity и
   карточка «Поделиться» работают на устройстве; CloudKit — приватная база
   пользователя, разработчику недоступна. Нажать Publish, если ASC попросит
   подтвердить. (Этот раздел API-ключом не меняется — только в веб-интерфейсе.)
3. **App Accessibility** (Accessibility Nutrition Labels): заполнить для
   iPhone и iPad по таблице `marketing.md` §7 — только проверенное.
4. **Pricing / Availability / Category** — без изменений (бесплатно,
   Education).
5. Остальное (тексты, скриншоты, review notes) загрузит `deliver` из
   репозитория. Если отправляете руками — тексты из `marketing.md` §1.

## 5. Выпуск

1. `git tag v2.0.0 && git push origin v2.0.0` → Actions «Release to App Store».
2. Следить за прогоном: скриншоты → сборка → TestFlight → ревью. Если
   скриншоты падают на раннере — перезапустить job (симуляторы иногда
   медленно стартуют).
3. После «Ready for Distribution» (или ручного Release) — раздел 7.

## 6. Featuring Nomination

ASC → приложение → **Featuring → Nominations → «+» → Create Nomination**.
Роль: Account Holder / Admin / App Manager / Marketing. Тексты — `marketing.md`
§6. Тип — App Enhancements; дата — дата выхода. Подать **минимум за 2 недели**
(лучше за 3–6). После одобрения E1 — вернуться и прикрепить событие.

## 7. Growth & Marketing

Все ресурсы — в `marketing.md` и `assets/`. Делать после того, как версия 2.0
одобрена (раньше Asset Library и PPO недоступны отдельно от версии).

1. **Asset Library** — загрузить header (21:9) и search result (3:2), проверить
   превью на всех размерах, Submit for Review (роль Admin / App Manager).
2. **In-App Events** — E1 «Новый режим вспоминания» в день выхода; E2
   «Неделя без пропусков» — со следующего понедельника, анонс за 7 дней.
   Не отправлять, пока версия в ревью.
3. **Custom Product Pages** — CPP-1 «С нуля», CPP-2 «iPad», CPP-3
   «Грамматика B1–B2»: свой Promotional Text, порядок скриншотов, ключевые
   слова (из списка ключевых слов приложения, без пересечений), deep link
   `lorito://today`. Отправить на ревью. Ссылки страниц — в соцсети и Apple Ads.
4. **Product Page Optimization** — через ~2 недели после выхода: тест первого
   скриншота (Recall / Today против текущего Onboarding), 50 % трафика,
   ≥ 14 дней.
5. **Promote Your App** — в приложении App Store Connect на iPhone: готовые
   картинки для соцсетей со ссылкой на страницу.
6. Через 2–4 недели: посмотреть App Analytics (конверсия страницы, CPP, события
   — аналитика события появляется после ≥ 5 загрузок из него), решить, что
   оставить.

## Чего здесь нет и почему

- **Apple Ads** — не настраивались; CPP-1 и CPP-2 рассчитаны на рекламные
  группы, если решите запускать.
- **Universal Links** — события и CPP используют `lorito://today`. Apple
  рекомендует universal link; для этого нужен `apple-app-site-association` на
  домене и Associated Domains в App ID — отдельная задача.
- **Картинки на «обжитых» данных** — см. примечание в начале `marketing.md`.
