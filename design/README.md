# Lorito — дизайн «Plumaje»

Исходники редизайна. Реализация идёт через OpenSpec-изменения
(`openspec/changes/`), этот каталог — референс и источник ассетов.

## Что где

| Путь | Что это |
|---|---|
| `brand/tokens.json` | Токены: цвета (light/dark), шрифты, отступы, радиусы. Источник истины для `LoritoColor` / `LoritoFont` / `LoritoSpacing` / `LoritoRadius`. |
| `brand/AppIcon*.svg` | Векторные исходники иконки: light, dark, tinted (iOS 18+). |
| `brand/AppIcon-preview.png` | Превью иконки в маске и на малых размерах. |
| `mockups/*.dc.html` | Исходники макетов с дизайн-холста (формат Design Component; рендерятся только в холсте). |
| `../Lorito/Assets.xcassets/AppIcon.appiconset/` | Иконка в приложении: `icon_1024.png`, `_dark`, `_tinted`. |
| `../Packages/LoritoKit/Sources/DesignSystem/Resources/Fonts/` | Статические TTF (инстансы из вариативных Google Fonts) + лицензии OFL. |

Холст с макетами: https://claude.ai/artifact/C7pCNDDHPe4doaViBKqT6T (приватный —
для других открывается через Share).

## Принципы

1. **Сначала вспомни, потом смотри.** Карточка открывается вопросом (`recall-first-study`).
2. **Одно действие на экран.** Главная кнопка внизу, в зоне большого пальца; высота 56 pt.
3. **Два голоса.** Русский интерфейс — Onest; всё испанское — Instrument Serif Italic
   цвета `accent`; заголовки и цифры — Unbounded.
4. **Режим фокуса.** Сессия всегда на `ink`, независимо от темы.
5. **¡ ¿ как бренд-глиф.** Иконка, «¡Hola!», «¡Olé!», «¿el или la?».

## Иконка

`¡` из Unbounded ExtraBold: стебель — Lima `#CBEF6B`, точка заменена кругом
Chile `#E5482A` — глаз попугая. Фон: Loro `#0E7C47` (light), Tinta `#0F1A14`
(dark), чёрный + оттенки серого (tinted). Перегенерация PNG из SVG — любой
рендерер в 1024×1024 без альфа-канала (App Store не принимает прозрачность в
основной иконке).

## Шрифты и лицензии

Unbounded, Onest, Instrument Serif — SIL Open Font License 1.1 (тексты рядом
со шрифтами). Встраивание в приложение разрешено; продавать шрифты отдельно
нельзя. PostScript-имена:

- `Unbounded-Bold`, `Unbounded-ExtraBold`
- `Onest-Regular`, `Onest-Medium`, `Onest-SemiBold`, `Onest-Bold`
- `InstrumentSerif-Regular`, `InstrumentSerif-Italic`

Instrument Serif не содержит кириллицу — использовать только для испанского.
