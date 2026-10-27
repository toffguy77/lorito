import SwiftUI
import Domain
import DesignSystem

/// The progress screen: a prominent current streak, the best streak, and study
/// counts. Shows an encouraging zero state when there's no history yet.
public struct StatsView: View {
    @State private var model: StatsModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(BuddyModel.self) private var buddy: BuddyModel?

    private var isRegular: Bool { sizeClass == .regular }

    public init(store: UserDataStore, catalog: ContentCatalog) {
        _model = State(initialValue: StatsModel(store: store, catalog: catalog))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                Text("Прогресс")
                    .loritoStyle(.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                    .loritoTitleFit(lines: 1)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, LoritoSpacing.xs)

                if isRegular {
                    // Dashboard: streak tiles in one row, heatmap at full width.
                    HStack(spacing: LoritoSpacing.sm) {
                        streakTile
                        statTile("лучшая серия", model.stats.bestStreak)
                        statTile("повторений всего", model.stats.studiedAllTime)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    heatmapCard
                    HStack(alignment: .top, spacing: LoritoSpacing.sm) {
                        if !model.memory.isEmpty { memoryCard }
                        VStack(spacing: LoritoSpacing.sm - 2) {
                            statTile("сегодня", model.stats.studiedToday)
                            statTile("за неделю", model.stats.studiedThisWeek)
                        }
                        .frame(maxWidth: 280)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: LoritoSpacing.sm - 2) {
                        streakTile
                        VStack(spacing: LoritoSpacing.sm - 2) {
                            statTile("лучшая серия", model.stats.bestStreak)
                            statTile("повторений всего", model.stats.studiedAllTime)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: LoritoSpacing.sm - 2) {
                        statTile("сегодня", model.stats.studiedToday)
                        statTile("за неделю", model.stats.studiedThisWeek)
                    }

                    heatmapCard

                    if !model.memory.isEmpty {
                        memoryCard
                    }
                }

                if !model.hasHistory {
                    Text("Начните учиться сегодня — и заложите первый день серии!")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .padding(.top, LoritoSpacing.sm)
                }

                if let buddy { BuddyCard(model: buddy).padding(.top, LoritoSpacing.sm) }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.vertical, LoritoSpacing.lg)
            .frame(maxWidth: isRegular ? 1100 : LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm - 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("12 недель").font(LoritoFont.bodyStrong)
                Spacer()
                Text("\(model.windowTotal) \(RussianPlural.form(model.windowTotal, one: "повторение", few: "повторения", many: "повторений"))")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
            }
            .foregroundStyle(LoritoColor.textPrimary)
            ActivityHeatmap(
                days: zip(model.activity, model.buckets).map { HeatmapDay(day: $0.day, count: $0.count, bucket: $1) },
                calendar: .learningDay,
                cellHeight: isRegular ? 30 : 18
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(heatmapSummary)
            ActivityHeatmapLegend()
        }
        .padding(.horizontal, LoritoSpacing.md + 2)
        .padding(.vertical, LoritoSpacing.md)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
    }

    /// One-line VoiceOver summary of the whole grid.
    private var heatmapSummary: String {
        let active = model.activity.filter { $0.count > 0 }.count
        return "Активность за 12 недель: \(model.windowTotal) повторений, занятий в \(active) из \(model.activity.count) дней"
    }

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm - 2) {
            HStack(alignment: .firstTextBaseline) {
                Text("В долгой памяти").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                Spacer()
                Text("интервал от \(StatsConstants.longTermIntervalDays) дня")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
            }
            ForEach(model.memory, id: \.level) { row in
                HStack(spacing: LoritoSpacing.xs) {
                    Text(row.level.rawValue)
                        .loritoStyle(LoritoTextStyle.heading.sized(13))
                        .foregroundStyle(LoritoColor.textPrimary)
                        .frame(minWidth: 32, alignment: .leading)
                    ProgressView(value: Double(row.longTerm), total: Double(max(row.total, 1)))
                        .tint(LoritoColor.accent)
                        .background(LoritoColor.surfaceSunken, in: Capsule())
                    Text("\(row.longTerm)/\(row.total)")
                        .font(LoritoFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(LoritoColor.textPrimary)
                        .frame(minWidth: 44, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.level.rawValue): \(row.longTerm) из \(row.total) карточек в долгой памяти")
            }
        }
        .padding(.horizontal, LoritoSpacing.md + 2)
        .padding(.vertical, LoritoSpacing.md)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
    }

    private var streakTile: some View {
        VStack(alignment: .leading) {
            Image(systemName: "flame.fill")
                .font(.system(size: 26, weight: .semibold))
                .accessibilityHidden(true)
            Spacer(minLength: LoritoSpacing.md)
            Text("\(model.stats.currentStreak)")
                .loritoStyle(LoritoTextStyle.number.sized(52))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(dayWord(model.stats.currentStreak))
                .font(LoritoFont.bodyStrong)
            HStack(spacing: LoritoSpacing.xxs) {
                Image(systemName: "snowflake")
                    .accessibilityHidden(true)
                Text("заморозки: \(model.freezes) из \(StreakConstants.maxFreezes)")
            }
            .font(LoritoFont.caption)
            .padding(.top, LoritoSpacing.xxs)
        }
        .foregroundStyle(LoritoColor.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md + 2)
        .frame(minHeight: 140)
        .background(LoritoColor.danger, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Текущая серия: \(model.stats.currentStreak) \(dayWord(model.stats.currentStreak)), заморозки: \(model.freezes) из \(StreakConstants.maxFreezes)")
        .accessibilityIdentifier("stats.streak")
    }

    private func statTile(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .loritoStyle(.heading)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(title)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, LoritoSpacing.md - 2)
        .padding(.vertical, LoritoSpacing.sm)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md + 2, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// Russian plural for "день/дня/дней".
    private func dayWord(_ n: Int) -> String {
        let mod100 = n % 100, mod10 = n % 10
        let unit: String
        if (11...14).contains(mod100) { unit = "дней" }
        else if mod10 == 1 { unit = "день" }
        else if (2...4).contains(mod10) { unit = "дня" }
        else { unit = "дней" }
        return "\(unit) подряд"
    }
}
