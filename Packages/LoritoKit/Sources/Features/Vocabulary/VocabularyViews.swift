import SwiftUI
import Domain
import DesignSystem

/// Word session in focus mode.
struct WordSessionView: View {
    @Bindable var model: WordSessionModel
    let onClose: () -> Void
    @Environment(\.speechService) private var speech

    var body: some View {
        VStack(spacing: LoritoSpacing.md) {
            if let c = model.current {
                SessionTopBar(segments: SessionProgressBar.segments(current: model.index, total: model.items.count),
                              position: "\(model.index + 1)/\(model.items.count)", onClose: onClose)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.top, LoritoSpacing.sm)
                ScrollView {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        let w = model.shown ?? c.word
                        if model.mode == .recognition { recognition(w) } else { production(w) }
                        otherForms
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                }
                actions
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.bottom, LoritoSpacing.md)
            } else {
                SessionCompleteView(subtitle: "Слова на сегодня пройдены.", onClose: onClose)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
    }

    @ViewBuilder
    private func recognition(_ w: Word) -> some View {
        Text("Вспомните перевод").loritoStyle(.label).foregroundStyle(LoritoColor.highlight)
        SpanishText(w.display, size: .display, color: LoritoColor.onInk)
            .accessibilityIdentifier("words.front")
        Button { speech?.speak(w.es, context: .content) } label: {
            Label("Послушать", systemImage: "speaker.wave.2.fill").font(LoritoFont.bodyStrong)
        }
        .buttonStyle(PrimaryButtonStyle(.outline))
        if model.isRevealed {
            Text(w.ru.isEmpty ? "Перевод не добавлен" : w.ru).loritoStyle(.heading).foregroundStyle(LoritoColor.onInk)
                .accessibilityIdentifier("words.translation")
            if !w.exampleEs.isEmpty {
                SpanishText(w.exampleEs, size: .custom(LoritoTextStyle.spanishInline.size), color: LoritoColor.onInk)
                Text(w.exampleRu).font(LoritoFont.body).foregroundStyle(LoritoColor.onInkSecondary)
            }
        }
    }

    @ViewBuilder
    private func production(_ w: Word) -> some View {
        Text("Напишите по-испански" + (w.isNoun ? " (с артиклем)" : "")).loritoStyle(.label).foregroundStyle(LoritoColor.highlight)
        Text(w.ru).loritoStyle(.heading).foregroundStyle(LoritoColor.onInk)
        TextField("", text: $model.typed, prompt: Text("ответ").foregroundStyle(LoritoColor.onInkSecondary))
            .autocorrectionDisabled()
            .font(LoritoFont.body)
            .foregroundStyle(LoritoColor.onInk)
            .padding(.horizontal, LoritoSpacing.md)
            .frame(minHeight: LoritoLayout.primaryButtonHeight)
            .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
            .disabled(model.check != nil)
            .accessibilityIdentifier("words.answer")
        HStack(spacing: LoritoSpacing.xs) {
            ForEach(ConjugationDrillModel.accents, id: \.self) { ch in
                Button(ch) { model.typed += ch }
                    .font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.onInk)
                    .frame(minWidth: LoritoLayout.minTouchTarget, minHeight: LoritoLayout.minTouchTarget)
                    .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous))
            }
        }
        if let r = model.check {
            Text(feedback(r)).font(LoritoFont.bodyStrong)
                .foregroundStyle(r.verdict == .correct ? LoritoColor.highlight : LoritoColor.onInk)
                .accessibilityIdentifier("words.feedback")
            if r.verdict != .correct {
                SpanishText(r.expected, size: .custom(LoritoTextStyle.spanishInline.size), color: LoritoColor.onInk)
            }
        }
    }

    @ViewBuilder
    private var otherForms: some View {
        ForEach(model.otherForms, id: \.variant) { f in
            HStack(alignment: .firstTextBaseline, spacing: LoritoSpacing.xs) {
                Text(VariantMarkup.noteTitle([f.variant]) + ":").font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                SpanishText(f.text, size: .custom(LoritoTextStyle.spanishInline.size), color: LoritoColor.onInk)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("words.otherForm.\(f.variant.code)")
        }
    }

    private func feedback(_ r: VocabularyCheck) -> String {
        switch (r.verdict, r.note) {
        case (.correct, _): "Верно"
        case (_, .missingArticle): "Почти: не хватает артикля"
        case (_, .genderMistake): "Ошибка в роде: другой артикль"
        case (.almost, _): "Почти: проверьте ударения"
        default: "Неверно"
        }
    }

    @ViewBuilder
    private var actions: some View {
        if model.mode == .recognition {
            if model.isRevealed {
                GradeButtons { model.selfGrade($0.domain) }
            } else {
                PrimaryButton("Показать перевод", variant: .highlight) { model.reveal() }
                    .accessibilityIdentifier("words.reveal")
            }
        } else if model.check == nil {
            PrimaryButton("Проверить", variant: .highlight) { model.submit() }
                .accessibilityIdentifier("words.check")
        } else {
            PrimaryButton("Дальше", variant: .highlight) { model.next() }
                .accessibilityIdentifier("words.next")
        }
    }
}

/// Decks: select / deselect, progress per deck, the personal deck with delete.
struct DecksView: View {
    @Bindable var model: VocabularyModel

    var body: some View {
        List {
            Section("Мои слова") {
                if model.personalEntries.isEmpty {
                    Text("Нажмите и удерживайте испанское слово в карточке → «В мои слова».")
                        .font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                }
                ForEach(model.personalEntries, id: \.id) { e in
                    VStack(alignment: .leading) {
                        SpanishText(e.es, size: .custom(LoritoTextStyle.spanishInline.size), color: LoritoColor.textPrimary)
                        if !e.ru.isEmpty { Text(e.ru).font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary) }
                    }
                    .accessibilityIdentifier("words.personal.\(e.id)")
                    .swipeActions { Button("Удалить", role: .destructive) { model.deletePersonal(e.id) } }
                    .contextMenu { Button("Удалить", role: .destructive) { model.deletePersonal(e.id) } }
                }
            }
            ForEach(CEFRLevel.allCases) { level in
                let decks = model.decks.filter { $0.level == level }
                if !decks.isEmpty {
                    Section(level.rawValue) {
                        ForEach(decks) { deck in
                            let p = model.progress(deck)
                            Button { model.toggle(deck) } label: {
                                HStack {
                                    Image(systemName: model.isSelected(deck) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(LoritoColor.accent).accessibilityHidden(true)
                                    Text(deck.titleRu).foregroundStyle(LoritoColor.textPrimary)
                                    Spacer()
                                    Text("\(p.started)/\(p.total)").font(LoritoFont.caption).monospacedDigit()
                                        .foregroundStyle(LoritoColor.textSecondary)
                                }
                            }
                            .accessibilityAddTraits(model.isSelected(deck) ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .navigationTitle("Слова")
        .onAppear { model.refresh() }
    }
}

/// «В мои слова» for a word outside the decks: add a translation, then save.
struct UnknownWordSheet: View {
    let text: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var ru = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Слово") { SpanishText(text, size: .custom(22), color: LoritoColor.textPrimary) }
                Section("Перевод") {
                    TextField("например: рано вставать", text: $ru).accessibilityIdentifier("words.unknown.ru")
                }
            }
            .navigationTitle("В мои слова")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Сохранить") { onSave(ru) }.accessibilityIdentifier("words.unknown.save") }
            }
        }
    }
}
