import SwiftUI
import Domain
import DesignSystem

/// First-run onboarding: pick a target level (auto-including lower levels), then
/// optionally narrow the themes. Enforces the non-empty-scope guard before it
/// can finish. UI copy is in Russian.
public struct OnboardingView: View {
    @State private var model: ScopeSelectionModel
    @State private var step: Step = .level
    private let onComplete: () -> Void

    private enum Step { case level, themes }

    public init(model: ScopeSelectionModel, onComplete: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .level: levelStep
            case .themes: themeStep
            }
        }
        .background(LoritoColor.surface.ignoresSafeArea())
    }

    // MARK: - Level step

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Ваш уровень",
                subtitle: "Выберите цель — все уровни ниже будут включены автоматически."
            )

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LoritoSpacing.sm) {
                    ForEach(model.allLevels) { level in
                        SelectableChip(
                            title: level.rawValue,
                            isSelected: model.includedLevels.contains(level)
                        ) {
                            model.selectLevel(level)
                            model.selectAllThemes()
                        }
                    }
                }
                .padding(.horizontal, LoritoSpacing.lg)

                if model.targetLevel != nil {
                    Text("Включено: \(model.includedLevels.map(\.rawValue).joined(separator: ", "))")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LoritoSpacing.lg)
                        .padding(.top, LoritoSpacing.sm)
                }
            }

            primaryButton(title: "Далее", enabled: model.targetLevel != nil) {
                step = .themes
            }
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Theme step

    private var themeStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Что изучать",
                subtitle: "По умолчанию выбраны все темы. Можно оставить только нужные."
            )

            ScrollView {
                LazyVStack(spacing: LoritoSpacing.xs) {
                    ForEach(model.availableThemes) { theme in
                        SelectableChip(
                            title: "\(theme.level.rawValue) · \(theme.title)",
                            isSelected: model.isThemeSelected(theme.id)
                        ) {
                            model.toggleTheme(theme.id)
                        }
                    }
                }
                .padding(.horizontal, LoritoSpacing.lg)
            }

            if !model.isStudyable {
                Text("Выберите хотя бы одну тему, чтобы продолжить.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.danger)
                    .padding(.horizontal, LoritoSpacing.lg)
            }

            HStack(spacing: LoritoSpacing.sm) {
                Button("Назад") { step = .level }
                    .font(LoritoFont.body.weight(.semibold))
                    .foregroundStyle(LoritoColor.textSecondary)
                    .padding(.vertical, LoritoSpacing.sm)
                    .padding(.horizontal, LoritoSpacing.lg)

                primaryButton(title: "Начать", enabled: model.isStudyable) {
                    if model.persist(completingOnboarding: true) {
                        onComplete()
                    }
                }
            }
            .padding(.horizontal, LoritoSpacing.lg)
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Shared pieces

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(title)
                .font(LoritoFont.title)
                .foregroundStyle(LoritoColor.textPrimary)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .padding(.horizontal, LoritoSpacing.lg)
    }

    private func primaryButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LoritoSpacing.sm)
                .background(
                    enabled ? LoritoColor.accent : LoritoColor.segmentTrack,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.horizontal, LoritoSpacing.lg)
    }
}
