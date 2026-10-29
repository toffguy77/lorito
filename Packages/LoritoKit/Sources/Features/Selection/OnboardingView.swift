import SwiftUI
import Domain
import DesignSystem

/// Onboarding: level (manual list or the placement test) → themes → goal →
/// Spanish variant → pace → sound → reminders. Enforces the non-empty-scope guard
/// before it can finish. A first run stores the placement result and the one-off
/// first-session boost; a revisit (from Settings, or once after an update) starts
/// prefilled, can be closed at any step and changes no progress. UI copy is in Russian.
public struct OnboardingView: View {
    @State private var model: ScopeSelectionModel
    @State private var setup: OnboardingSetupModel
    @State private var goals: GoalSettingsModel
    @State private var step: Step = .level
    @State private var reminderTime: Date
    /// Set while/after taking the placement test; cleared by a manual level choice.
    @State private var placement: PlacementModel?
    /// Revisit: a level lowering that resets progress, awaiting confirmation.
    @State private var pendingLowering: PendingLowering?
    private let mode: OnboardingMode
    private let onComplete: () -> Void
    private let onClose: (() -> Void)?
    private let reminders: ReminderService?
    /// The reminder already configured (revisit): skipping or keeping it changes nothing.
    private let existingReminder: Date?
    @Environment(\.loritoUITesting) private var uiTesting

    private enum Step: Int, CaseIterable {
        case level, placement, themes, goal, variant, pace, sound, reminders

        var analyticsName: OnboardingStepName {
            switch self {
            case .level, .placement: return .level
            case .themes: return .themes
            case .goal: return .goal
            case .variant: return .variant
            case .pace: return .pace
            case .sound: return .sound
            case .reminders: return .reminders
            }
        }

        /// Position in the progress bar (the placement test belongs to the level step).
        var index: Int { self == .level ? 0 : rawValue - 1 }
        static let count = 7
    }

    public init(
        model: ScopeSelectionModel,
        reminders: ReminderService? = nil,
        mode: OnboardingMode = .firstRun,
        onClose: (() -> Void)? = nil,
        onComplete: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        _setup = State(initialValue: OnboardingSetupModel(store: model.store))
        _goals = State(initialValue: GoalSettingsModel(store: model.store, catalog: model.catalog))
        self.reminders = reminders
        self.mode = mode
        self.onClose = onClose
        self.onComplete = onComplete
        let settings = (try? model.store.loadSettings()) ?? .default
        let today = Calendar.current.startOfDay(for: Date())
        let existing = settings.remindersEnabled
            ? settings.reminderMinutes.first.flatMap { Calendar.current.date(byAdding: .minute, value: $0, to: today) }
            : nil
        existingReminder = existing
        // Default reminder time: 20:00 local (or the one already set).
        let base = Calendar.current.date(
            bySettingHour: ReminderConfig.defaultTime.hour,
            minute: ReminderConfig.defaultTime.minute, second: 0, of: Date()
        ) ?? Date()
        _reminderTime = State(initialValue: existing ?? base)
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .level: levelStep
            case .placement: placementStep
            case .themes: themeStep
            case .goal: goalStep
            case .variant: variantStep
            case .pace: paceStep
            case .sound: soundStep
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
                if let level = model.targetLevel, let lowering = model.loweringNeedingConfirmation(to: level) {
                    pendingLowering = lowering
                } else {
                    step = .themes
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
        .padding(.vertical, LoritoSpacing.lg)
        // The reset itself happens when the themes step saves the scope.
        .levelLoweringConfirmation($pendingLowering) { _ in step = .themes }
    }

    // MARK: - Placement step

    @ViewBuilder
    private var placementStep: some View {
        if let placement {
            PlacementView(model: placement, onAccept: { level in
                model.selectLevel(level)
                model.selectAllThemes()
                if let lowering = model.loweringNeedingConfirmation(to: level) {
                    step = .level                        // asks there before the reset
                    pendingLowering = lowering
                } else {
                    step = .themes
                }
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
                    // Saved now so the goal step offers the chosen levels.
                    model.persist()
                    goals.reload()
                    step = .goal
                }
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Goal step

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Цель",
                subtitle: "Уровень к дате или экзамен DELE A2 / CCSE. Lorito подстроит темп и покажет обратный отсчёт. Можно без цели."
            )
            GoalSettingsView(model: goals)
                .scrollContentBackground(.hidden)
            setupFooter(back: .themes) { step = .variant }
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Variant step

    private var variantStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Какой испанский",
                subtitle: "Влияет на слова, формы и озвучку. Остальные варианты показываются рядом."
            )
            ScrollView {
                VStack(spacing: LoritoSpacing.xs) {
                    ForEach(SpanishVariant.allCases, id: \.self) { variant in
                        SelectableChip(title: variant.title, isSelected: setup.variant == variant) {
                            setup.variant = variant
                        }
                        .accessibilityIdentifier("onboarding.variant.\(variant.rawValue)")
                    }
                }
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }
            setupFooter(back: .goal) {
                setup.saveVariant()
                step = .pace
            }
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Pace step

    private var paceStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Темп",
                subtitle: "Сколько нового в день. Повторения добавляются сами. Всё меняется в Настройках."
            )
            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                    card {
                        Stepper(value: $setup.cardsPerDay, in: OnboardingSetupModel.cardsRange) {
                            Text("Новых карточек в день: \(setup.cardsPerDay)")
                                .font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                        }
                        .accessibilityIdentifier("onboarding.cards")
                    }
                    card {
                        Toggle(isOn: $setup.wordsEnabled) {
                            Text("Учить слова").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                        }
                        .tint(LoritoColor.accent)
                        .accessibilityIdentifier("onboarding.words")
                        if setup.wordsEnabled {
                            Stepper(value: $setup.wordsPerDay, in: 1...20) {
                                Text("Новых слов в день: \(setup.wordsPerDay)")
                                    .font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                            }
                        }
                    }
                    card {
                        Toggle(isOn: $setup.conjugationsEnabled) {
                            Text("Тренировать спряжения").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                        }
                        .tint(LoritoColor.accent)
                        .accessibilityIdentifier("onboarding.conjugations")
                        if setup.conjugationsEnabled {
                            Stepper(value: $setup.conjugationsPerDay, in: 1...UserSettings.conjugationRange.upperBound) {
                                Text("Новых спряжений в день: \(setup.conjugationsPerDay)")
                                    .font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                            }
                        }
                    }
                    Text("Всё новое за день укладывается в общий лимит — \(DailyBudget.defaultTotal).")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textSecondary)
                }
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }
            setupFooter(back: .variant) {
                setup.savePace()
                step = .sound
            }
        }
        .padding(.vertical, LoritoSpacing.lg)
    }

    // MARK: - Sound step

    private var soundStep: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
            header(
                title: "Звук",
                subtitle: "Испанские фразы озвучиваются по нажатию — голос устройства, офлайн."
            )
            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                    card {
                        Text("Скорость").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                        Picker("Скорость", selection: $setup.rate) {
                            ForEach(SpeechRate.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("onboarding.rate")
                    }
                    card {
                        Toggle(isOn: $setup.playWhenSilent) {
                            Text("Звук в беззвучном режиме").font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                        }
                        .tint(LoritoColor.accent)
                    }
                }
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }
            setupFooter(back: .pace) {
                setup.saveSound()
                step = .reminders
            }
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

    /// Complete onboarding, optionally enabling a reminder at the chosen time.
    /// Reminder-enable runs first (writes `reminderConfig`), then scope +
    /// completion are persisted; each loads settings fresh so neither clobbers
    /// the other. Onboarding completes regardless of the authorization outcome.
    /// A revisit keeps an existing reminder when the time is unchanged or skipped.
    private func finish(enableReminderAt time: Date?) {
        Task {
            if let time, let reminders, !sameMinute(time, existingReminder) {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                _ = await reminders.enable(
                    times: [ReminderTime(hour: comps.hour ?? ReminderConfig.defaultTime.hour,
                                         minute: comps.minute ?? ReminderConfig.defaultTime.minute)]
                )
            }
            if OnboardingFinish.complete(mode, scope: model, placement: placement) {
                if mode == .firstRun { AnalyticsService.shared.record(.onboardingCompleted) }
                onComplete()
            }
        }
    }

    private func sameMinute(_ a: Date, _ b: Date?) -> Bool {
        guard let b else { return false }
        let ca = Calendar.current.dateComponents([.hour, .minute], from: a)
        let cb = Calendar.current.dateComponents([.hour, .minute], from: b)
        return ca.hour == cb.hour && ca.minute == cb.minute
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

    /// Footer of the setup steps: back, skip (keeps the current values), next (saves).
    private func setupFooter(back: Step, next: @escaping () -> Void) -> some View {
        VStack(spacing: LoritoSpacing.xs) {
            HStack(spacing: LoritoSpacing.sm) {
                Button("Назад") { step = back }
                    .buttonStyle(PrimaryButtonStyle(.outline))
                    .fixedSize()
                primaryButton(title: "Далее", enabled: true, action: next)
            }
            Button("Пропустить") {
                step = Step(rawValue: step.rawValue + 1) ?? .reminders
            }
            .font(LoritoFont.bodyStrong)
            .foregroundStyle(LoritoColor.textSecondary)
            .frame(minHeight: LoritoLayout.minTouchTarget)
        }
        .padding(.horizontal, LoritoSpacing.screenGutter)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) { content() }
            .padding(LoritoSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            HStack(spacing: LoritoSpacing.sm) {
                HStack(spacing: 6) {
                    ForEach(0..<Step.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= step.index ? LoritoColor.textPrimary : LoritoColor.separator)
                            .frame(height: 5)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Шаг \(step.index + 1) из \(Step.count)")
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(LoritoFont.bodyStrong)
                            .foregroundStyle(LoritoColor.textSecondary)
                            .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                    }
                    .accessibilityLabel("Закрыть")
                    .accessibilityIdentifier("onboarding.close")
                }
            }
            .padding(.bottom, LoritoSpacing.xs)
            Text(title)
                .loritoStyle(LoritoTextStyle.title.sized(32))
                .foregroundStyle(LoritoColor.textPrimary)
                .loritoTitleFit(lines: 2)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, LoritoSpacing.screenGutter)
    }

    private func primaryButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        PrimaryButton(title, variant: .ink, action: action)
            .disabled(!enabled)
    }
}
