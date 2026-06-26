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
            VStack(spacing: LoritoSpacing.lg) {
                Text("Прогресс")
                    .font(LoritoFont.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                streakCard

                HStack(spacing: LoritoSpacing.sm) {
                    statTile("Сегодня", model.stats.studiedToday)
                    statTile("За неделю", model.stats.studiedThisWeek)
                    statTile("Всего", model.stats.studiedAllTime)
                }

                if !model.hasHistory {
                    Text("Начните учиться сегодня — и заложите первый день серии! 🌱")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, LoritoSpacing.sm)
                }

                Spacer()
            }
            .padding(LoritoSpacing.lg)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .onAppear { model.refresh() }
    }

    private var streakCard: some View {
        VStack(spacing: LoritoSpacing.xs) {
            Text("🔥").font(.system(size: 44))
            Text("\(model.stats.currentStreak)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(LoritoColor.onAccent)
            Text(dayWord(model.stats.currentStreak))
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent.opacity(0.9))
            Text("Лучшая серия: \(model.stats.bestStreak)")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.onAccentSoft)
                .padding(.top, LoritoSpacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LoritoSpacing.lg)
        .background(LoritoColor.accent, in: RoundedRectangle(cornerRadius: LoritoRadius.lg))
        .loritoElevation()
    }

    private func statTile(_ title: String, _ value: Int) -> some View {
        VStack(spacing: LoritoSpacing.xxs) {
            Text("\(value)")
                .font(LoritoFont.title)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(title)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LoritoSpacing.md)
        .background(LoritoColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
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
