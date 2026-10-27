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
    @Environment(\.colorScheme) private var colorScheme
    let onClose: () -> Void

    public init(model: ExerciseSessionModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if let exercise = model.current {
                content(exercise)
            } else {
                SessionCompleteView(subtitle: "Все упражнения пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }

    private func content(_ exercise: Exercise) -> some View {
        VStack(spacing: LoritoSpacing.md) {
            SessionTopBar(
                segments: SessionProgressBar.segments(current: model.index, total: model.count),
                position: model.positionText.replacingOccurrences(of: " ", with: ""),
                onClose: onClose
            )
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                    Text("\(exercise.level.rawValue) · \(exercise.card)")
                        .loritoStyle(.label)
                        .foregroundStyle(LoritoColor.highlight)
                    CardContentView(exercise.prompt, tone: .ink)

                    inputSection(exercise)

                    if let check = model.lastCheck {
                        feedback(check, exercise: exercise)
                    } else if model.isRevealed {
                        reveal(exercise)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .frame(maxWidth: LoritoLayout.readingWidth)
                .frame(maxWidth: .infinity)
            }

            actionArea
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
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
                        AnswerText(option, color: optionForeground(option))
                        Spacer()
                    }
                    .padding(.horizontal, LoritoSpacing.md)
                    .frame(minHeight: LoritoLayout.primaryButtonHeight)
                    .background(optionBackground(option), in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous)
                        .strokeBorder(optionBorder(option), lineWidth: 2))
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(option)
                .buttonStyle(.plain)
                .disabled(model.isResolved)
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private var textInput: some View {
        @Bindable var model = model
        return TextField("", text: $model.typedText, prompt: Text("Ваш ответ").foregroundStyle(LoritoColor.onInkSecondary))
            .autocorrectionDisabled()
            .font(LoritoFont.body)
            .foregroundStyle(LoritoColor.onInk)
            .tint(LoritoColor.highlight)
            .padding(.horizontal, LoritoSpacing.md)
            .frame(minHeight: LoritoLayout.primaryButtonHeight)
            .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            .disabled(model.isResolved)
            .padding(.top, LoritoSpacing.sm)
            .onSubmit { if model.canSubmit { model.submit() } }
    }

    private var wordOrderInput: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            // The sentence built so far.
            Group {
                if model.ordering.isEmpty {
                    Text("Нажимайте слова по порядку")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                } else {
                    AnswerText(model.ordering.joined(separator: " "), color: LoritoColor.onInk)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .padding(LoritoSpacing.md)
            .overlay(RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous)
                .strokeBorder(LoritoColor.inkTrack, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))

            ChipRow(items: model.remainingTokens) { token in
                if !model.isResolved { model.placeToken(token) }
            }

            if !model.ordering.isEmpty && !model.isResolved {
                Button("Сбросить") { model.resetOrdering() }
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
            }
        }
        .padding(.top, LoritoSpacing.sm)
    }

    private var matchingInput: some View {
        @Bindable var model = model
        return VStack(spacing: LoritoSpacing.sm) {
            ForEach(model.matchingLefts, id: \.self) { left in
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    AnswerText(left, color: LoritoColor.onInk)
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
                    AnswerText(option.label, color: LoritoColor.onInk)
                    HStack(spacing: LoritoSpacing.sm) {
                        ForEach(model.pictureOptions, id: \.image) { pic in
                            Button { if !model.isResolved { model.matches[option.label] = pic.image } } label: {
                                assetThumbnail(pic.image)
                                    .overlay(RoundedRectangle(cornerRadius: LoritoRadius.sm)
                                        .strokeBorder(model.matches[option.label] == pic.image ? LoritoColor.highlight : LoritoColor.inkTrack,
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
                Text(image).font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
            }
        }
        .padding(LoritoSpacing.xxs)
        .frame(width: 64, height: 64)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.sm))
    }

    // MARK: Feedback / reveal

    private func feedback(_ check: ExerciseCheck, exercise: Exercise) -> some View {
        let foreground = check.isCorrect ? LoritoColor.onHighlight : LoritoColor.textPrimary
        return VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Label(check.isCorrect ? "Верно" : "Неверно",
                  systemImage: check.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .loritoStyle(.heading)
                .foregroundStyle(check.isCorrect ? LoritoColor.onHighlight : LoritoColor.dangerText)
            if !check.isCorrect {
                HStack(alignment: .firstTextBaseline, spacing: LoritoSpacing.xs) {
                    Text("Правильный ответ:").font(LoritoFont.body).foregroundStyle(foreground)
                    AnswerText(check.correctAnswer, color: LoritoColor.accent)
                }
                .accessibilityElement(children: .combine)
            }
            if !exercise.explanation.isEmpty { CardContentView(exercise.explanation) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md)
        .background(check.isCorrect ? LoritoColor.highlight : LoritoColor.surfaceRaised,
                    in: RoundedRectangle(cornerRadius: LoritoRadius.md + 4, style: .continuous))
        .environment(\.colorScheme, check.isCorrect ? .light : (colorScheme))
    }

    private func reveal(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Образец ответа").loritoStyle(.label).foregroundStyle(LoritoColor.highlight)
            AnswerText(model.referenceAnswer, color: LoritoColor.onInk)
            if !exercise.explanation.isEmpty { CardContentView(exercise.explanation, tone: .ink) }
            Text("Оцените свой ответ:").font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.onInkSecondary).padding(.top, LoritoSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.md)
        .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md + 4, style: .continuous))
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
        PrimaryButton(title, variant: .highlight, action: action)
            .disabled(!enabled)
    }

    // MARK: Option styling

    private func optionBackground(_ option: String) -> Color {
        if model.isResolved, let check = model.lastCheck {
            if option == check.correctAnswer { return LoritoColor.highlight }
            if option == model.selectedOption { return LoritoColor.dangerSoft }
        }
        return LoritoColor.inkRaised
    }

    private func optionForeground(_ option: String) -> Color {
        if model.isResolved, let check = model.lastCheck {
            if option == check.correctAnswer { return LoritoColor.onHighlight }
            if option == model.selectedOption { return LoritoColor.dangerText }
        }
        return LoritoColor.onInk
    }

    private func optionBorder(_ option: String) -> Color {
        if !model.isResolved, option == model.selectedOption { return LoritoColor.highlight }
        return .clear
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
                        AnswerText(item, color: item == selected ? LoritoColor.onHighlight : LoritoColor.onInk)
                            .padding(.horizontal, LoritoSpacing.md)
                            .frame(minHeight: LoritoLayout.minTouchTarget)
                            .background(item == selected ? LoritoColor.highlight : LoritoColor.inkRaised,
                                        in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous))
                    }
                    .accessibilityLabel(item)
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
