import SwiftUI
import Domain
import Content
import DesignSystem

/// The interactive practice screen: renders the prompt, offers the input
/// affordance for the exercise type, checks the answer on submit, then shows
/// feedback (auto-checkable types) or reveals the reference for self-grading
/// (`free-response`) before continuing.
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

                    inputSection(exercise)

                    if let check = model.lastCheck {
                        feedback(check, exercise: exercise)
                    } else if model.isRevealed {
                        reveal(exercise)
                    }
                }
                .padding(LoritoSpacing.md)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }

            actionArea
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.md)
                .padding(.bottom, LoritoSpacing.md)
        }
    }

    // MARK: Inputs (per type)

    @ViewBuilder
    private func inputSection(_ exercise: Exercise) -> some View {
        if model.isMultipleChoice {
            optionButtons
        } else if model.isTextInput {
            textInput
        } else if model.isWordOrder {
            wordOrderInput
        } else if model.isMatching {
            matchingInput
        } else if model.isPictureMatching {
            pictureMatchingInput
        }
    }

    private var optionButtons: some View {
        VStack(spacing: LoritoSpacing.sm) {
            ForEach(model.options, id: \.self) { option in
                Button { model.selectedOption = option } label: {
                    HStack {
                        Text(option).font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                        Spacer()
                    }
                    .padding(LoritoSpacing.sm)
                    .background(optionBackground(option), in: RoundedRectangle(cornerRadius: LoritoRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: LoritoRadius.md)
                        .strokeBorder(optionBorder(option), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .disabled(model.isResolved)
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
            .disabled(model.isResolved)
            .padding(.top, LoritoSpacing.sm)
            .onSubmit { if model.canSubmit { model.submit() } }
    }

    private var wordOrderInput: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            // The sentence built so far.
            Text(model.ordering.isEmpty ? "Нажимайте слова по порядку" : model.ordering.joined(separator: " "))
                .font(LoritoFont.body)
                .foregroundStyle(model.ordering.isEmpty ? LoritoColor.textTertiary : LoritoColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LoritoSpacing.sm)
                .background(LoritoColor.surface, in: RoundedRectangle(cornerRadius: LoritoRadius.md))

            ChipRow(items: model.remainingTokens) { token in
                if !model.isResolved { model.placeToken(token) }
            }

            if !model.ordering.isEmpty && !model.isResolved {
                Button("Сбросить") { model.resetOrdering() }
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private var matchingInput: some View {
        @Bindable var model = model
        return VStack(spacing: LoritoSpacing.sm) {
            ForEach(model.matchingLefts, id: \.self) { left in
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    Text(left).font(LoritoFont.body.weight(.semibold)).foregroundStyle(LoritoColor.textPrimary)
                    ChipRow(items: model.matchingRights, selected: model.matches[left]) { right in
                        if !model.isResolved { model.matches[left] = right }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private var pictureMatchingInput: some View {
        VStack(spacing: LoritoSpacing.sm) {
            ForEach(model.pictureOptions, id: \.label) { option in
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    Text(option.label).font(LoritoFont.body.weight(.semibold)).foregroundStyle(LoritoColor.textPrimary)
                    HStack(spacing: LoritoSpacing.sm) {
                        ForEach(model.pictureOptions, id: \.image) { pic in
                            Button { if !model.isResolved { model.matches[option.label] = pic.image } } label: {
                                assetThumbnail(pic.image)
                                    .overlay(RoundedRectangle(cornerRadius: LoritoRadius.md)
                                        .strokeBorder(model.matches[option.label] == pic.image ? LoritoColor.accent : LoritoColor.separator,
                                                      lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.isResolved)
                        }
                    }
                }
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private func assetThumbnail(_ image: String) -> some View {
        Group {
            if let url = ContentLoader.exerciseAssetURL(image) {
                AsyncImage(url: url) { img in img.resizable().scaledToFit() } placeholder: { ProgressView() }
            } else {
                Text(image).font(LoritoFont.caption).foregroundStyle(LoritoColor.textTertiary)
            }
        }
        .frame(width: 64, height: 64)
        .background(LoritoColor.surface, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
    }

    // MARK: Feedback / reveal

    private func feedback(_ check: ExerciseCheck, exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Label(check.isCorrect ? "Верно" : "Неверно",
                  systemImage: check.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(LoritoFont.body.weight(.semibold))
                .foregroundStyle(check.isCorrect ? LoritoColor.success : LoritoColor.warning)
            if !check.isCorrect {
                Text("Правильный ответ: \(check.correctAnswer)")
                    .font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
            }
            if !exercise.explanation.isEmpty { CardContentView(exercise.explanation) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.sm)
        .background((check.isCorrect ? LoritoColor.success : LoritoColor.warning).opacity(0.10),
                   in: RoundedRectangle(cornerRadius: LoritoRadius.md))
        .padding(.top, LoritoSpacing.sm)
    }

    private func reveal(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Образец ответа").font(LoritoFont.caption).foregroundStyle(LoritoColor.textTertiary)
            Text(model.referenceAnswer).font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
            if !exercise.explanation.isEmpty { CardContentView(exercise.explanation) }
            Text("Оцените свой ответ:").font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.textSecondary).padding(.top, LoritoSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.sm)
        .background(LoritoColor.info.opacity(0.10), in: RoundedRectangle(cornerRadius: LoritoRadius.md))
        .padding(.top, LoritoSpacing.sm)
    }

    // MARK: Action area

    @ViewBuilder
    private var actionArea: some View {
        if model.isRevealed {
            // free-response: self-grade with the four SM-2 buttons (this advances).
            GradeButtons { grade in model.selfGrade(grade.domain) }
        } else if model.lastCheck != nil {
            primaryButton(model.isLast ? "Готово" : "Продолжить") { model.advance() }
        } else {
            primaryButton("Проверить", enabled: model.canSubmit) { model.submit() }
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
        if model.isResolved, let check = model.lastCheck {
            if option == check.correctAnswer { return LoritoColor.success.opacity(0.15) }
            if option == model.selectedOption { return LoritoColor.warning.opacity(0.15) }
        } else if option == model.selectedOption {
            return LoritoColor.accent.opacity(0.12)
        }
        return LoritoColor.surface
    }

    private func optionBorder(_ option: String) -> Color {
        if model.isResolved, let check = model.lastCheck {
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
            Text("Готово!").font(LoritoFont.title).foregroundStyle(LoritoColor.textPrimary)
            Text("Все упражнения пройдены.").font(LoritoFont.body).foregroundStyle(LoritoColor.textSecondary)
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

/// A wrapping-ish row of selectable text chips (single line, horizontally scrollable).
private struct ChipRow: View {
    let items: [String]
    var selected: String? = nil
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LoritoSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    Button { onTap(item) } label: {
                        Text(item)
                            .font(LoritoFont.body)
                            .foregroundStyle(LoritoColor.textPrimary)
                            .padding(.horizontal, LoritoSpacing.sm)
                            .padding(.vertical, LoritoSpacing.xs)
                            .background(item == selected ? LoritoColor.accent.opacity(0.15) : LoritoColor.surface,
                                       in: Capsule())
                            .overlay(Capsule().strokeBorder(item == selected ? LoritoColor.accent : LoritoColor.separator,
                                                            lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
