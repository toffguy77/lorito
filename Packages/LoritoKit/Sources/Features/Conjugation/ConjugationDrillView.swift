import SwiftUI
import Domain
import DesignSystem

/// Conjugation drill in focus mode: infinitive + translation, tense, two
/// person fields, the accent row, check, per-person feedback, and a link to the
/// tense's grammar card.
public struct ConjugationDrillView: View {
    @Bindable var model: ConjugationDrillModel
    let onOpenCard: (String) -> Void
    let onClose: () -> Void
    @FocusState private var focus: Int?

    public init(model: ConjugationDrillModel, onOpenCard: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.onOpenCard = onOpenCard
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: LoritoSpacing.md) {
            if let item = model.current {
                SessionTopBar(segments: SessionProgressBar.segments(current: model.index, total: model.items.count),
                              position: model.positionText, onClose: onClose)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.top, LoritoSpacing.sm)
                ScrollView {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        Text(item.tense.es)
                            .loritoStyle(.label)
                            .foregroundStyle(LoritoColor.highlight)
                        SpanishText(item.verb.infinitive, size: .display, color: LoritoColor.onInk)
                        Text(item.verb.ru + (item.verb.reflexive ? " (возвратный)" : ""))
                            .font(LoritoFont.body)
                            .foregroundStyle(LoritoColor.onInkSecondary)
                        ForEach(model.persons.indices, id: \.self) { slot in
                            // Rows can be re-evaluated while `next()` swaps persons; stay in bounds.
                            if slot < model.persons.count, slot < model.answers.count { field(slot) }
                        }
                        accentRow
                        Button {
                            onOpenCard(item.tense.card)
                        } label: {
                            Label("Правило: \(item.tense.es)", systemImage: "book")
                                .font(LoritoFont.bodyStrong)
                                .foregroundStyle(LoritoColor.highlight)
                        }
                        .frame(minHeight: LoritoLayout.minTouchTarget)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                }
                Group {
                    if model.results == nil {
                        PrimaryButton("Проверить", variant: .highlight) {
                            focus = nil
                            model.check()
                        }
                        .disabled(!model.canCheck)
                        .accessibilityIdentifier("conj.check")
                    } else {
                        PrimaryButton(model.index + 1 < model.items.count ? "Дальше" : "Готово", variant: .highlight) {
                            model.next()
                        }
                        .accessibilityIdentifier("conj.next")
                    }
                }
                .frame(maxWidth: LoritoLayout.readingWidth)
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.bottom, LoritoSpacing.md)
            } else {
                SessionCompleteView(subtitle: "Спряжения на сегодня пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
        .onChange(of: focus) { _, f in if let f { model.focusedField = f } }
    }

    private func field(_ slot: Int) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(model.label(slot))
                .font(LoritoFont.bodyStrong)
                .foregroundStyle(LoritoColor.onInk)
            TextField("", text: $model.answers[slot], prompt: Text("форма").foregroundStyle(LoritoColor.onInkSecondary))
                .noAutocapitalization()
                .autocorrectionDisabled()
                .focused($focus, equals: slot)
                .font(LoritoFont.body)
                .foregroundStyle(LoritoColor.onInk)
                .tint(LoritoColor.highlight)
                .padding(.horizontal, LoritoSpacing.md)
                .frame(minHeight: LoritoLayout.primaryButtonHeight)
                .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .disabled(model.results != nil)
                .accessibilityLabel(model.label(slot))
                .accessibilityIdentifier("conj.field.\(slot)")
            if let r = model.results?[slot] {
                feedback(r)
            }
        }
    }

    private func feedback(_ r: ConjugationCheck) -> some View {
        let (title, color): (String, Color) = switch r.verdict {
        case .correct: ("Верно", LoritoColor.highlight)
        case .almost: ("Почти", LoritoColor.highlight)
        case .wrong: ("Неверно", LoritoColor.danger)
        }
        return HStack(spacing: LoritoSpacing.xs) {
            Text(title).font(LoritoFont.bodyStrong).foregroundStyle(color)
            if r.verdict != .correct {
                SpanishText(r.expected, size: .custom(LoritoTextStyle.spanishInline.size), color: LoritoColor.onInk)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("conj.feedback")
    }

    private var accentRow: some View {
        HStack(spacing: LoritoSpacing.xs) {
            ForEach(ConjugationDrillModel.accents, id: \.self) { ch in
                Button(ch) { model.insertAccent(ch) }
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.onInk)
                    .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                    .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous))
                    .accessibilityLabel("Вставить \(ch)")
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func noAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}
