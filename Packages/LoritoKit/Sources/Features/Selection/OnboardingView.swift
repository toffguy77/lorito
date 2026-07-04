import SwiftUI
import Domain
import DesignSystem

/// First-run onboarding: pick a target level (auto-including lower levels), then
/// optionally narrow the themes. Enforces the non-empty-scope guard before it
/// can finish. UI copy is in Russian.
public struct OnboardingView: View {
    @State private var model: ScopeSelectionModel
    @State private var step: Step = .level
    @State private var reminderTime: Date
    private let onComplete: () -> Void
    private let reminders: ReminderService?

    private enum Step { case level, themes, reminders }

    public init(
        model: ScopeSelectionModel,
        reminders: ReminderService? = nil,
        onComplete: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        self.reminders = reminders
        self.onComplete = onComplete
        // Default reminder time: 20:00 local.
        let base = Calendar.current.date(
            bySettingHour: ReminderConfig.defaultTime.hour,
            minute: ReminderConfig.defaultTime.minute, second: 0, of: Date()
        ) ?? Date()
        _reminderTime = State(initialValue: base)
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .level: levelStep
            case .themes: themeStep
            case .reminders: reminderStep
            }
        }
        .frame(maxWidth: LoritoLayout.readingWidth)
        .frame(maxWidth: .infinity)
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

                primaryButton(title: "Далее", enabled: model.isStudyable) {
                    step = .reminders
                }
            }
            .padding(.horizontal, LoritoSpacing.lg)
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Reminder step

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Напоминания",
                subtitle: "Выберите время ежедневного напоминания, чтобы не терять серию. Можно изменить позже в Настройках."
            )

            reminderTimePicker
                .padding(.horizontal, LoritoSpacing.lg)

            Spacer()

            HStack(spacing: LoritoSpacing.sm) {
                Button("Пропустить") { finish(enableReminderAt: nil) }
                    .font(LoritoFont.body.weight(.semibold))
                    .foregroundStyle(LoritoColor.textSecondary)
                    .padding(.vertical, LoritoSpacing.sm)
                    .padding(.horizontal, LoritoSpacing.lg)

                primaryButton(title: "Готово", enabled: true) {
                    finish(enableReminderAt: reminderTime)
                }
            }
            .padding(.horizontal, LoritoSpacing.lg)
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    /// Complete onboarding, optionally enabling a first reminder at the chosen
    /// time. Reminder-enable runs first (writes `reminderConfig`), then scope +
    /// completion are persisted; each loads settings fresh so neither clobbers
    /// the other. Onboarding completes regardless of the authorization outcome.
    private func finish(enableReminderAt time: Date?) {
        Task {
            if let time, let reminders {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                _ = await reminders.enable(
                    times: [ReminderTime(hour: comps.hour ?? ReminderConfig.defaultTime.hour,
                                         minute: comps.minute ?? ReminderConfig.defaultTime.minute)]
                )
            }
            if model.persist(completingOnboarding: true) {
                onComplete()
            }
        }
    }

    @ViewBuilder
    private var reminderTimePicker: some View {
        let picker = DatePicker("Время", selection: $reminderTime, displayedComponents: .hourAndMinute)
            .labelsHidden()
        #if os(iOS)
        picker.datePickerStyle(.wheel)
        #else
        picker
        #endif
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
