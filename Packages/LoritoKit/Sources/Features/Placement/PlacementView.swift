import SwiftUI
import Domain
import DesignSystem
import Content

/// Onboarding's placement test on a focus surface: one question at a time
/// (multiple choice, picture matching, word order), no per-question feedback,
/// then the result with the proposed level, «ваши 3 ловушки» and the opt-in
/// «Пропустить то, что я знаю».
struct PlacementView: View {
    @Bindable var model: PlacementModel
    let onAccept: (CEFRLevel) -> Void
    let onCancel: () -> Void
    @Environment(\.spanishSpanActions) private var spanActions

    var body: some View {
        Group {
            if model.isFinished {
                resultView
            } else if let exercise = model.current {
                question(exercise)
            } else {
                // No testable content: fall back to the manual list.
                Color.clear.onAppear(perform: onCancel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }

    // MARK: Question

    private func question(_ exercise: Exercise) -> some View {
        VStack(spacing: LoritoSpacing.md) {
            HStack {
                Text("Вопрос \(model.questionNumber) · \(exercise.level.rawValue)")
                    .loritoStyle(.label)
                    .foregroundStyle(LoritoColor.highlight)
                Spacer()
                Button("Отмена", action: onCancel)
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
            }
            .padding(.horizontal, LoritoSpacing.screenGutter)
            .padding(.top, LoritoSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                    CardContentView(exercise.prompt, tone: .ink)
                    input(exercise)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LoritoSpacing.screenGutter)
            }

            PrimaryButton("Ответить", variant: .highlight) { model.submit() }
                .disabled(!model.canSubmit)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
        }
        .frame(maxWidth: LoritoLayout.readingWidth)
    }

    @ViewBuilder
    private func input(_ exercise: Exercise) -> some View {
        switch exercise.kind {
        case .multipleChoice:
            VStack(spacing: LoritoSpacing.sm) {
                ForEach(model.options, id: \.self) { option in
                    choice(option, selected: model.selectedOption == option) {
                        model.selectedOption = option
                        spanActions.performPrimary(option)
                    }
                }
            }
        case .wordOrder:
            wordOrder
        case .pictureMatching:
            pictureMatching
        default:
            EmptyView()
        }
    }

    private func choice(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                AnswerText(text, color: selected ? LoritoColor.onHighlight : LoritoColor.onInk)
                Spacer()
            }
            .padding(.horizontal, LoritoSpacing.md)
            .frame(minHeight: LoritoLayout.primaryButtonHeight)
            .background(selected ? LoritoColor.highlight : LoritoColor.inkRaised,
                        in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .accessibilityLabel(text)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .buttonStyle(.plain)
    }

    private var wordOrder: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Group {
                if model.ordering.isEmpty {
                    Text("Нажимайте слова по порядку")
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                } else {
                    AnswerText(model.ordering.joined(separator: " "), color: LoritoColor.onInk, interaction: .standalone)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .padding(LoritoSpacing.md)
            .overlay(RoundedRectangle(cornerRadius: LoritoRadius.lg, style: .continuous)
                .strokeBorder(LoritoColor.inkTrack, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
            ForEach(Array(model.remainingTokens.enumerated()), id: \.offset) { _, token in
                choice(token, selected: false) { model.placeToken(token) }
            }
            if !model.ordering.isEmpty {
                Button("Сбросить") { model.resetOrdering() }
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
            }
        }
    }

    private var pictureMatching: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            ForEach(model.pictureOptions, id: \.label) { option in
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    AnswerText(option.label, color: LoritoColor.onInk, interaction: .standalone)
                    HStack(spacing: LoritoSpacing.sm) {
                        ForEach(model.pictureOptions, id: \.image) { pic in
                            Button { model.matches[option.label] = pic.image } label: {
                                thumbnail(pic.image)
                                    .overlay(RoundedRectangle(cornerRadius: LoritoRadius.sm)
                                        .strokeBorder(model.matches[option.label] == pic.image
                                                      ? LoritoColor.highlight : LoritoColor.inkTrack, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Картинка \(pic.image) для \(option.label)")
                        }
                    }
                }
            }
        }
    }

    private func thumbnail(_ image: String) -> some View {
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

    // MARK: Result

    private var resultView: some View {
        VStack(spacing: LoritoSpacing.md) {
            ScrollView {
                VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                    Text("Ваш уровень")
                        .loritoStyle(.label)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                    Text(model.result?.proposedTarget.rawValue ?? "")
                        .loritoStyle(LoritoTextStyle.title.sized(56))
                        .foregroundStyle(LoritoColor.highlight)
                        .accessibilityIdentifier("placement.proposed")
                    Text(knownText)
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.onInk)

                    if !model.traps.isEmpty { traps }

                    levelPicker

                    if model.result?.highestKnown != nil {
                        Toggle(isOn: $model.skipKnown) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Пропустить то, что я знаю")
                                    .font(LoritoFont.bodyStrong)
                                    .foregroundStyle(LoritoColor.onInk)
                                Text("Карточки, на которые вы ответили верно, сразу встанут в повторение.")
                                    .font(LoritoFont.caption)
                                    .foregroundStyle(LoritoColor.onInkSecondary)
                            }
                        }
                        .tint(LoritoColor.highlight)
                        .accessibilityIdentifier("placement.skipKnown")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.top, LoritoSpacing.lg)
            }
            PrimaryButton("Учить с \(model.chosenLevel.rawValue)", variant: .highlight) { onAccept(model.chosenLevel) }
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
        }
        .frame(maxWidth: LoritoLayout.readingWidth)
    }

    private var knownText: String {
        guard let r = model.result else { return "" }
        let asked = RussianPlural.form(r.questionCount, one: "вопрос", few: "вопроса", many: "вопросов")
        if r.knownLevels.isEmpty { return "\(r.questionCount) \(asked). Начнём с основ." }
        let levels = r.knownLevels.map(\.rawValue).joined(separator: ", ")
        return "\(r.questionCount) \(asked). Уже знакомо: \(levels) — эти карточки придут позже, после новых."
    }

    private var traps: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text(model.traps.count == 1 ? "Ваша ловушка" : "Ваши \(model.traps.count) ловушки")
                .loritoStyle(.label)
                .foregroundStyle(LoritoColor.onInkSecondary)
            ForEach(model.traps, id: \.cardID) { trap in
                HStack(alignment: .top, spacing: LoritoSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(LoritoColor.highlight)
                        .accessibilityHidden(true)
                    CardContentView(trap.text, tone: .ink)
                }
                .padding(LoritoSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            }
        }
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text("Или выберите другой уровень")
                .font(LoritoFont.caption)
                .foregroundStyle(LoritoColor.onInkSecondary)
            Picker("Уровень", selection: $model.chosenLevel) {
                ForEach(CEFRLevel.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("placement.levelPicker")
        }
    }
}
