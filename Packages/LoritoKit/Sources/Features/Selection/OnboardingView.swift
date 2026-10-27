import SwiftUI
import Domain
import DesignSystem

/// First-run onboarding: level (manual list or the placement test) → themes →
/// reminders. Enforces the non-empty-scope guard before it can finish. On
/// completion it stores the placement result and the one-off first-session
/// boost. UI copy is in Russian.
public struct OnboardingView: View {
    @State private var model: ScopeSelectionModel
    @State private var step: Step = .level
    @State private var reminderTime: Date
    /// Set while/after taking the placement test; cleared by a manual level choice.
    @State private var placement: PlacementModel?
    private let onComplete: () -> Void
    private let reminders: ReminderService?
    @Environment(\.loritoUITesting) private var uiTesting

    private enum Step {
        case level, placement, themes, reminders

        var analyticsName: OnboardingStepName {
            switch self {
            case .level, .placement: return .level
            case .themes: return .themes
            case .reminders: return .reminders
            }
        }
    }

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
            case .placement: placementStep
            case .themes: themeStep
            case .reminders: reminderStep
            }
        }
        .onAppear { AnalyticsService.shared.record(.onboardingStep(step.analyticsName)) }
        .onChange(of: step) { _, step in AnalyticsService.shared.record(.onboardingStep(step.analyticsName)) }
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
                VStack(spacing: 6) {
                    ForEach(model.allLevels) { level in
                        LevelRow(level: level, state: rowState(level)) {
                            placement = nil                       // manual choice
                            model.selectLevel(level)
                            model.selectAllThemes()
                        }
                    }
                }
                .padding(.horizontal, LoritoSpacing.screenGutter)

                Button {
                    placement = PlacementModel(
                        catalog: model.catalog,
                        scripted: uiTesting ? PlacementModel.uiTestScript(from: CommandLine.arguments) : nil)
                    step = .placement
                } label: {
                    Label("Не знаю — проверить за 2 минуты", systemImage: "checklist")
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(LoritoColor.accent)
                        .frame(maxWidth: .infinity, minHeight: LoritoLayout.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("placement.start")
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.top, LoritoSpacing.sm)

                if model.targetLevel != nil {
                    Text("Включено: \(model.includedLevels.map(\.rawValue).joined(separator: ", "))")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, LoritoSpacing.screenGutter)
                        .padding(.top, LoritoSpacing.sm)
                }
            }

            primaryButton(title: "Далее", enabled: model.targetLevel != nil) {
                step = .themes
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Placement step

    @ViewBuilder
    private var placementStep: some View {
        if let placement {
            PlacementView(model: placement, onAccept: { level in
                model.selectLevel(level)
                model.selectAllThemes()
                step = .themes
            }, onCancel: {
                self.placement = nil
                step = .level
            })
        }
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
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }

            if !model.isStudyable {
                Text("Выберите хотя бы одну тему, чтобы продолжить.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.dangerText)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
            }

            HStack(spacing: LoritoSpacing.sm) {
                Button("Назад") { step = .level }
                    .buttonStyle(PrimaryButtonStyle(.outline))
                    .fixedSize()

                primaryButton(title: "Далее", enabled: model.isStudyable) {
                    step = .reminders
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
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
                .padding(.horizontal, LoritoSpacing.screenGutter)

            Spacer()

            HStack(spacing: LoritoSpacing.sm) {
                Button("Пропустить") { finish(enableReminderAt: nil) }
                    .buttonStyle(PrimaryButtonStyle(.outline))
                    .fixedSize()

                primaryButton(title: "Готово", enabled: true) {
                    finish(enableReminderAt: reminderTime)
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
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
                // Placement result (known level, opt-in seeding), then the one-off
                // first-session boost with the failed-test cards first.
                let today = Date()
                let seeded = placement.flatMap { try? $0.apply(to: model.store, today: today) } ?? []
                let failed = (placement?.failedCardIDs ?? []).filter { !seeded.contains($0) }
                FirstSessionBoostStore.shared.save(FirstSessionBoost(day: today, priorityCardIDs: failed))
                AnalyticsService.shared.record(.onboardingCompleted)
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

    private func rowState(_ level: CEFRLevel) -> LevelRow.State {
        if level == model.targetLevel { return .target }
        return model.includedLevels.contains(level) ? .included : .off
    }

    private var stepIndex: Int {
        switch step {
        case .level, .placement: return 0
        case .themes: return 1
        case .reminders: return 2
        }
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIndex ? LoritoColor.textPrimary : LoritoColor.separator)
                        .frame(height: 5)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Шаг \(stepIndex + 1) из 3")
            .padding(.bottom, LoritoSpacing.xs)
            Text(title)
                .loritoStyle(LoritoTextStyle.title.sized(32))
                .foregroundStyle(LoritoColor.textPrimary)
                .loritoTitleFit(lines: 2)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
        }
        .padding(.horizontal, LoritoSpacing.screenGutter)
    }

    private func primaryButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        PrimaryButton(title, variant: .ink, action: action)
            .disabled(!enabled)
    }
}
