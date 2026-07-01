import SwiftUI
import Domain
import DesignSystem

/// The interactive practice screen: renders the prompt, offers the input
/// affordance for the exercise type (option buttons or a text field), checks the
/// answer on submit, then shows correct/incorrect feedback with the correct
/// answer and explanation before continuing.
public struct ExerciseSessionView: View {
    @State private var model: ExerciseSessionModel
    let onClose: () -> Void

    public init(model: ExerciseSessionModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let exercise = model.current {
                    content(exercise)
                } else {
                    completionState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LoritoColor.surfaceSecondary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Закрыть", action: onClose)
                        .foregroundStyle(LoritoColor.textSecondary)
                }
            }
        }
    }

    private func content(_ exercise: Exercise) -> some View {
        VStack(spacing: LoritoSpacing.md) {
            Text(model.positionText)
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textTertiary)
                .padding(.top, LoritoSpacing.xs)

            ScrollView {
                StudyCardContainer {
                    LevelChip(level: exercise.level.rawValue, theme: exercise.themeID)
                    CardContentView(exercise.prompt)

                    if model.isMultipleChoice {
                        optionButtons(exercise)
                    } else {
                        textInput
                    }

                    if let check = model.lastCheck {
                        feedback(check, exercise: exercise)
                    }
                }
                .padding(LoritoSpacing.md)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }

            actionButton
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.bottom, LoritoSpacing.md)
        }
    }

    // MARK: Inputs

    private func optionButtons(_ exercise: Exercise) -> some View {
        VStack(spacing: LoritoSpacing.sm) {
            ForEach(model.options, id: \.self) { option in
                Button { model.selectedOption = option } label: {
                    HStack {
                        Text(option)
                            .font(LoritoFont.body)
                            .foregroundStyle(LoritoColor.textPrimary)
                        Spacer()
                    }
                    .padding(LoritoSpacing.sm)
                    .background(optionBackground(option), in: RoundedRectangle(cornerRadius: LoritoRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: LoritoRadius.md)
                            .strokeBorder(optionBorder(option), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.isChecked)
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private var textInput: some View {
        @Bindable var model = model
        return TextField("Ваш ответ", text: $model.typedText)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .font(LoritoFont.body)
            .disabled(model.isChecked)
            .padding(.top, LoritoSpacing.sm)
            .onSubmit { if model.canSubmit { model.submit() } }
    }

    // MARK: Feedback

    private func feedback(_ check: ExerciseCheck, exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Label(check.isCorrect ? "Верно" : "Неверно",
                  systemImage: check.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(check.isCorrect ? LoritoColor.success : LoritoColor.warning)

            if !check.isCorrect {
                Text("Правильный ответ: \(check.correctAnswer)")
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textPrimary)
            }
            if !exercise.explanation.isEmpty {
                CardContentView(exercise.explanation)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.sm)
        .background(
            (check.isCorrect ? LoritoColor.success : LoritoColor.warning).opacity(0.10),
            in: RoundedRectangle(cornerRadius: LoritoRadius.md)
        )
        .padding(.top, LoritoSpacing.sm)
    }

    private var actionButton: some View {
        Group {
            if model.isChecked {
                primaryButton(model.current == nil ? "Готово" : "Продолжить") { model.advance() }
            } else {
                primaryButton("Проверить", enabled: model.canSubmit) { model.submit() }
            }
        }
    }

    private func primaryButton(_ title: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LoritoSpacing.sm)
                .background(enabled ? LoritoColor.accent : LoritoColor.accent.opacity(0.4),
                           in: RoundedRectangle(cornerRadius: LoritoRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Option styling

    private func optionBackground(_ option: String) -> Color {
        if model.isChecked, let check = model.lastCheck {
            if option == check.correctAnswer { return LoritoColor.success.opacity(0.15) }
            if option == model.selectedOption { return LoritoColor.warning.opacity(0.15) }
        } else if option == model.selectedOption {
            return LoritoColor.accent.opacity(0.12)
        }
        return LoritoColor.surface
    }

    private func optionBorder(_ option: String) -> Color {
        if model.isChecked, let check = model.lastCheck {
            if option == check.correctAnswer { return LoritoColor.success }
            if option == model.selectedOption { return LoritoColor.warning }
        } else if option == model.selectedOption {
            return LoritoColor.accent
        }
        return LoritoColor.separator
    }

    private var completionState: some View {
        VStack(spacing: LoritoSpacing.sm) {
            Text("🎉").font(.system(size: 52))
            Text("Готово!")
                .font(LoritoFont.title)
                .foregroundStyle(LoritoColor.textPrimary)
            Text("Все упражнения пройдены.")
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.textSecondary)
            Button("На главную", action: onClose)
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(LoritoColor.onAccent)
                .padding(.horizontal, LoritoSpacing.lg)
                .padding(.vertical, LoritoSpacing.sm)
                .background(LoritoColor.accent, in: Capsule())
                .padding(.top, LoritoSpacing.sm)
        }
        .padding(LoritoSpacing.xl)
    }
}
