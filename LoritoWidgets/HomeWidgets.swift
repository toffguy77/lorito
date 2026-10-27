import SwiftUI
import WidgetKit
import Domain
import DesignSystem
import WidgetSupport

/// Neutral state for a missing or unsupported snapshot.
struct OpenLoritoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("¡").font(LoritoFont.title).foregroundStyle(LoritoColor.highlight)
            Text("Откройте Lorito").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.onInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

/// Small: streak + cards waiting today.
struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lorito.streak", provider: SnapshotProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(LoritoColor.ink, for: .widget)
                .widgetURL(LoritoDeepLink.today)
        }
        .configurationDisplayName("Серия")
        .description("Серия дней и карточки на сегодня.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let state = entry.state {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("¡L").font(LoritoTextStyle.heading.sized(16).font).foregroundStyle(LoritoColor.highlight)
                    Spacer()
                    Image(systemName: "flame.fill").foregroundStyle(LoritoColor.danger)
                }
                Spacer()
                Text("\(state.streak)")
                    .font(LoritoTextStyle.number.sized(48).font)
                    .foregroundStyle(LoritoColor.highlight)
                    .minimumScaleFactor(0.5)
                Text(caption(state))
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .lineLimit(2)
            }
        } else {
            OpenLoritoView()
        }
    }

    private func caption(_ state: WidgetDayState) -> String {
        let days = RussianPlural.form(state.streak, one: "день", few: "дня", many: "дней")
        guard let remaining = state.remainingToday else { return days }
        return "\(days) · \(remaining) ждут"
    }
}

/// Small: the Spanish word of the day (from the trap of the day).
struct WordOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lorito.word", provider: SnapshotProvider()) { entry in
            WordOfDayView(entry: entry)
                .containerBackground(LoritoColor.surfaceRaised, for: .widget)
                .widgetURL(LoritoDeepLink.today)
        }
        .configurationDisplayName("Слово дня")
        .description("Испанское слово из ловушки дня.")
        .supportedFamilies([.systemSmall])
    }
}

struct WordOfDayView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let word = entry.snapshot?.wordOfDay {
            VStack(alignment: .leading, spacing: 6) {
                Text("Слово дня")
                    .loritoStyle(.label)
                    .foregroundStyle(LoritoColor.dangerText)
                Spacer()
                SpanishText(word.spanish, size: .custom(28), interactive: false)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                Text(word.note)
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            OpenLoritoView().environment(\.colorScheme, .dark)
        }
    }
}

/// Lock Screen: circular = cards left today; rectangular = streak at risk.
struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lorito.lockscreen", provider: SnapshotProvider()) { entry in
            LockScreenView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(LoritoDeepLink.today)
        }
        .configurationDisplayName("Lorito")
        .description("Карточки на сегодня и серия.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LockScreenView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill").font(.caption2)
                    Text(entry.state?.remainingToday.map(String.init) ?? "–")
                        .font(LoritoTextStyle.heading.sized(20).font)
                }
            }
            .accessibilityLabel("Карточек на сегодня: \(entry.state?.remainingToday.map(String.init) ?? "неизвестно")")
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(headline).font(LoritoFont.bodyStrong).lineLimit(1)
                Text(detail).font(LoritoFont.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headline: String {
        guard let state = entry.state else { return "Lorito" }
        if state.streakAtRisk { return "Серия \(state.streak) — ещё не сегодня" }
        if state.streak > 0 { return "Серия \(state.streak) · сегодня есть" }
        return "Начните серию сегодня"
    }

    private var detail: String {
        guard let state = entry.state else { return "Откройте приложение" }
        if let remaining = state.remainingToday, remaining > 0 { return "\(remaining) карточек ждут" }
        return state.streakAtRisk ? "Одна карточка спасёт её" : "Hasta mañana"
    }
}
