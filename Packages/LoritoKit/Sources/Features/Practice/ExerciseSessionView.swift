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
    @Environment(\.spanishSpanActions) private var spanActions
    @Environment(\.speechService) private var speech
    @State private var showPermissionExplanation = false
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
        .speechSilenceHint()
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
                    HStack {
                        Text("\(exercise.level.rawValue) · \(exercise.card)")
                            .loritoStyle(.label)
                            .foregroundStyle(LoritoColor.highlight)
                        Spacer()
                        SurfaceSpeakButton(spans: SpeakableText.spans(inMarkdown: exercise.prompt), tone: .ink)
                    }
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
        if model.isListenChoose {
            listeningControls
            optionButtons
        } else if model.isDictation {
            listeningControls
            textInput
        } else if model.isSpeak {
            speakInput
        } else if model.isMultipleChoice {
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
                Button {
                    model.selectedOption = option
                    spanActions.performPrimary(option)          // tap Spanish to hear it
                } label: {
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

    /// Play / replay / slow replay of the hidden `audio` text, and «Не могу слушать сейчас».
    private var listeningControls: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            HStack(spacing: LoritoSpacing.sm) {
                Button { play(.listeningExercise) } label: {
                    Label("Слушать", systemImage: "play.fill").font(LoritoFont.bodyStrong)
                }
                .accessibilityIdentifier("listen.play")
                Button { play(.listeningSlow) } label: {
                    Label("Медленно", systemImage: "tortoise.fill").font(LoritoFont.bodyStrong)
                }
                .accessibilityIdentifier("listen.slow")
            }
            .buttonStyle(PrimaryButtonStyle(.outline))
            if !model.isResolved {
                Button("Не могу слушать сейчас") { model.skipListening() }
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .accessibilityIdentifier("listen.skip")
            }
            // The spoken text appears only after submission.
            if model.isResolved, let audio = model.audioText {
                AnswerText(audio, color: LoritoColor.onInk, interaction: .standalone)
                    .accessibilityIdentifier("listen.revealed")
            }
        }
        .padding(.top, LoritoSpacing.sm)
        .onAppear { if !model.isResolved { play(.listeningExercise) } }
    }

    private func play(_ context: PlaybackContext) {
        guard let text = model.audioText else { return }
        speech?.speak(text, context: context)
    }

    /// `speak`: say the phrase; auto mode records and checks on device, otherwise
    /// the user plays the reference and grades themselves.
    private var speakInput: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            Text("Скажите вслух:").font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
            AnswerText(model.speakTarget, color: LoritoColor.onInk, interaction: .standalone)
            if model.speakIsAuto, !model.isResolved {
                Button {
                    if model.isRecording { model.stopRecording() } else { Task { await model.recordSpeech() } }
                } label: {
                    Label(model.isRecording ? "Стоп" : "Записать", systemImage: model.isRecording ? "stop.fill" : "mic.fill")
                        .font(LoritoFont.bodyStrong)
                }
                .buttonStyle(PrimaryButtonStyle(.outline))
                .accessibilityIdentifier("speak.record")
                if model.isRecording, let level = model.recognizer?.level {
                    ProgressView(value: Double(level)).tint(LoritoColor.highlight).accessibilityHidden(true)
                }
                if let transcript = model.transcript {
                    Text("Распознано: \(transcript)").font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                    Text("Не совпало — попробуйте ещё раз.").font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                }
            }
            if model.isResolved || !model.speakIsAuto {
                Button {
                    speech?.speak(model.speakTarget, context: .content)
                } label: {
                    Label("Послушать образец", systemImage: "speaker.wave.2.fill").font(LoritoFont.bodyStrong)
                }
                .buttonStyle(PrimaryButtonStyle(.outline))
            }
            if !model.isResolved {
                Button("Не могу говорить сейчас") { model.skipSpeaking() }
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.onInkSecondary)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .accessibilityIdentifier("speak.skip")
            }
        }
        .padding(.top, LoritoSpacing.sm)
        .onAppear { if model.needsSpeechPermission { showPermissionExplanation = true } }
        .sheet(isPresented: $showPermissionExplanation) {
            SpeechPermissionExplanation {
                showPermissionExplanation = false
                Task { await model.requestSpeechPermission() }
            } onLater: {
                showPermissionExplanation = false
            }
        }
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
                    AnswerText(model.ordering.joined(separator: " "), color: LoritoColor.onInk, interaction: .standalone)
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
                    AnswerText(left, color: LoritoColor.onInk, interaction: .standalone)
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
                    AnswerText(option.label, color: LoritoColor.onInk, interaction: .standalone)
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
            if check.isAlmost {
                Text("Почти: проверьте ударения").font(LoritoFont.bodyStrong).foregroundStyle(foreground)
            }
            if !check.isCorrect {
                HStack(alignment: .firstTextBaseline, spacing: LoritoSpacing.xs) {
                    Text("Правильный ответ:").font(LoritoFont.body).foregroundStyle(foreground)
                    AnswerText(check.correctAnswer, color: LoritoColor.accent, interaction: .standalone)
                }
                .accessibilityElement(children: .combine)
                if let diff = check.wordDiff, !diff.isEmpty {
                    Text(diff.map { "\($0.typed.isEmpty ? "—" : $0.typed) → \($0.expected.isEmpty ? "—" : $0.expected)" }
                            .joined(separator: ", "))
                        .font(LoritoFont.caption)
                        .foregroundStyle(foreground)
                }
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
            AnswerText(model.referenceAnswer, color: LoritoColor.onInk, interaction: .standalone)
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
            // free-response / self-assessed speak: self-grade (this advances).
            GradeButtons { grade in model.selfGrade(grade.domain) }
        } else if model.lastCheck != nil {
            primaryButton(model.isLast ? "Готово" : "Продолжить") { model.advance() }
        } else {
            primaryButton(model.isSpeak ? "Сравнить с образцом" : "Проверить", enabled: model.canSubmit) { model.submit() }
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
    @Environment(\.spanishSpanActions) private var spanActions
    let items: [String]
    var selected: String? = nil
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LoritoSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    Button {
                        onTap(item)
                        spanActions.performPrimary(item)            // tap a token to hear it
                    } label: {
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

/// One screen before the first microphone / speech prompt.
private struct SpeechPermissionExplanation: View {
    let onContinue: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            Image(systemName: "mic.circle").font(.system(size: 44)).foregroundStyle(LoritoColor.accent)
                .accessibilityHidden(true)
            Text("Проверка произношения").loritoStyle(.heading).foregroundStyle(LoritoColor.textPrimary)
            Text("Lorito послушает, как вы произносите фразу, и сравнит с образцом. Распознавание идёт только на этом устройстве — запись никуда не отправляется. Нужен доступ к микрофону и распознаванию речи.")
                .font(LoritoFont.body).foregroundStyle(LoritoColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("Продолжить", variant: .ink, action: onContinue)
            Button("Не сейчас", action: onLater).frame(minHeight: LoritoLayout.minTouchTarget)
        }
        .padding(LoritoSpacing.screenGutter)
        .presentationDetents([.medium])
    }
}
