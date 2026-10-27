import SwiftUI
import Domain
import DesignSystem

/// The progress screen: a prominent current streak, the best streak, and study
/// counts. Shows an encouraging zero state when there's no history yet.
public struct StatsView: View {
    @State private var model: StatsModel

    public init(store: UserDataStore) {
        _model = State(initialValue: StatsModel(store: store))
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

                HStack(spacing: LoritoSpacing.sm - 2) {
                    streakTile
                        .layoutPriority(1.3)
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

                if !model.hasHistory {
                    Text("Начните учиться сегодня — и заложите первый день серии!")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .padding(.top, LoritoSpacing.sm)
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.vertical, LoritoSpacing.lg)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
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
        }
        .foregroundStyle(LoritoColor.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md + 2)
        .frame(minHeight: 140)
        .background(LoritoColor.danger, in: RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Текущая серия: \(model.stats.currentStreak) \(dayWord(model.stats.currentStreak))")
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
