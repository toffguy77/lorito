import SwiftUI
import Domain
import DesignSystem

/// «Экзамены DELE и CCSE»: the three tracks.
public struct ExamsView: View {
    @State var model: ExamsModel

    public init(model: ExamsModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                Text("Пробные экзамены с таймером, разбор ошибок и готовность по частям. Lorito не связан с Instituto Cervantes; результат — оценка, не гарантия.")
                    .font(LoritoFont.caption)
                    .foregroundStyle(LoritoColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(ExamsModel.Track.allCases) { track in
                    NavigationLink {
                        ExamTrackView(model: model, track: track)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title).font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.textPrimary)
                                Text(track == .citizenship ? "DELE A2 + CCSE для гражданства Испании"
                                     : model.exams?.definition(track.rawValue)?.summary ?? "")
                                    .font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(LoritoColor.textSecondary).accessibilityHidden(true)
                        }
                        .padding(LoritoSpacing.md)
                        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exams.track.\(track.rawValue)")
                }
            }
            .padding(LoritoSpacing.screenGutter)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Экзамены DELE и CCSE")
        .onAppear { model.refresh() }
    }
}

/// A track: format, rules, verification date, readiness, countdown, attribution, mocks, history.
struct ExamTrackView: View {
    let model: ExamsModel
    let track: ExamsModel.Track
    @State private var runner: MockRunnerModel?
    @State private var paywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                ForEach(track.exams, id: \.self) { exam in examBlock(exam) }
            }
            .padding(LoritoSpacing.screenGutter)
            .frame(maxWidth: LoritoLayout.readingWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle(track.title)
        .focusModeCover(item: $runner, onDismiss: { model.refresh() }) { r in
            MockRunnerView(model: r) { runner = nil }
        }
        .sheet(isPresented: $paywall) {
            if let purchases = model.purchases {
                PaywallView(service: purchases, entry: .examPath) { paywall = false }
            }
        }
    }

    @ViewBuilder
    private func examBlock(_ exam: String) -> some View {
        if let def = model.exams?.definition(exam) {
            VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                Text(def.title).loritoStyle(.heading).foregroundStyle(LoritoColor.textPrimary)
                if let days = model.countdown(exam) {
                    Label("До экзамена: \(RussianPlural.days(days))", systemImage: "calendar")
                        .font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.accent)
                        .accessibilityIdentifier("exams.countdown.\(exam)")
                }
                if let summary = def.summary {
                    Text(summary).font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let fee = def.fee {
                    Text("Стоимость: \(fee)").font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                }
                Text("Проверено: \(def.verifiedOn). Сверяйте даты и цены на examenes.cervantes.es.")
                    .font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                readiness(exam, def: def)
                if exam == "ccse" {
                    Text(model.ccseAttribution ?? "Банк вопросов CCSE появится после импорта официального пособия Instituto Cervantes.")
                        .font(LoritoFont.caption).foregroundStyle(LoritoColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("exams.attribution")
                }
                ForEach(model.forms(exam), id: \.self) { form in
                    let open = model.canStart(exam, form: form)
                    Button {
                        if let r = model.start(exam, form: form) { runner = r } else { paywall = true }
                    } label: {
                        HStack {
                            Text(model.isPro ? "Пробный экзамен \(form)" :
                                    (open ? "Пробный экзамен \(form) — бесплатная часть" : "Пробный экзамен \(form)"))
                                .font(LoritoFont.bodyStrong)
                            Spacer()
                            Image(systemName: open ? "play.fill" : "lock.fill").accessibilityHidden(true)
                        }
                        .foregroundStyle(LoritoColor.textPrimary)
                        .padding(LoritoSpacing.md)
                        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exams.start.\(exam).\(form)")
                }
                history(exam, def: def)
            }
        }
    }

    private func readiness(_ exam: String, def: ExamDefinition) -> some View {
        let labels = model.readiness(exam)
        return VStack(alignment: .leading, spacing: 2) {
            Text("Готовность").loritoStyle(.label).foregroundStyle(LoritoColor.textSecondary)
            ForEach(def.groups) { g in
                Text("\(g.title): \(labels[g.id]?.title ?? ReadinessLabel.tooEarly.title)")
                    .font(LoritoFont.body).foregroundStyle(LoritoColor.textPrimary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("exams.readiness.\(exam)")
    }

    @ViewBuilder
    private func history(_ exam: String, def: ExamDefinition) -> some View {
        let past = model.attempts.filter { $0.examID == exam }
        if !past.isEmpty {
            Text("История").loritoStyle(.label).foregroundStyle(LoritoColor.textSecondary)
            ForEach(past) { a in
                HStack {
                    Text(a.startedAt.formatted(date: .abbreviated, time: .shortened)).font(LoritoFont.caption)
                    Spacer()
                    Text(status(a, def: def)).font(LoritoFont.caption)
                    if a.state == .inProgress, model.canStart(exam, form: max(a.form, 1)) {
                        Button("Продолжить") { runner = model.resume(a) }.font(LoritoFont.caption)
                    }
                }
                .foregroundStyle(LoritoColor.textPrimary)
                .accessibilityIdentifier("exams.history.\(exam)")
            }
        }
    }

    private func status(_ a: MockAttempt, def: ExamDefinition) -> String {
        switch a.state {
        case .inProgress: return "идёт"
        case .abandoned: return "прерван"
        case .completed:
            let r = MockRun.result(a, def: def)
            return (r.passed ? "сдан" : "не сдан") + (a.expired ? " (время вышло)" : "")
        }
    }
}

/// The mock in focus mode: timer, items of the running section, rubric self-check, results.
struct MockRunnerView: View {
    @Bindable var model: MockRunnerModel
    let onClose: () -> Void
    @Environment(\.speechService) private var speech
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: LoritoSpacing.md) {
            if model.isFinished {
                results
            } else if let section = model.section {
                header(section)
                ScrollView {
                    VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                        ForEach(model.sectionItems) { item in itemView(item) }
                    }
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                }
                PrimaryButton("Завершить часть", variant: .highlight) { model.submitSection() }
                    .padding(.horizontal, LoritoSpacing.screenGutter)
                    .padding(.bottom, LoritoSpacing.md)
                    .accessibilityIdentifier("mock.submit")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoritoColor.ink.ignoresSafeArea())
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.tick() } }
    }

    private func header(_ section: ExamSection) -> some View {
        HStack {
            Button("Прервать") { model.abandon() }
                .font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.onInkSecondary)
                .frame(minHeight: LoritoLayout.minTouchTarget)
            Spacer()
            Text(section.title).loritoStyle(.label).foregroundStyle(LoritoColor.highlight)
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = Int(model.remaining(at: context.date))
                Text(String(format: "%d:%02d", left / 60, left % 60))
                    .font(LoritoFont.bodyStrong).monospacedDigit().foregroundStyle(LoritoColor.onInk)
                    .accessibilityLabel("Осталось \(left / 60) мин")
                    .accessibilityValue("\(left)")
                    .accessibilityIdentifier("mock.timer")
                    .onChange(of: left) { _, l in if l <= 0 { model.tick() } }
            }
        }
        .padding(.horizontal, LoritoSpacing.screenGutter)
        .padding(.top, LoritoSpacing.sm)
    }

    @ViewBuilder
    private func itemView(_ item: ExamItem) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            switch item.kind {
            case .choice(let options, _):
                AnswerText(item.text, color: LoritoColor.onInk, interaction: .standalone)
                optionList(item, options)
            case .listeningTask(let script, let options, _):
                Button { speech?.speak(script, context: .listeningExercise) } label: {
                    Label("Слушать", systemImage: "play.fill").font(LoritoFont.bodyStrong)
                }
                .buttonStyle(PrimaryButtonStyle(.outline))
                AnswerText(item.text, color: LoritoColor.onInk, interaction: .standalone)
                optionList(item, options)
            case .writingTask(let prompt, let rubric):
                AnswerText(prompt, color: LoritoColor.onInk, interaction: .standalone)
                Text("Напишите ответ на бумаге или в заметках, затем отметьте, что получилось:")
                    .font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                rubricView(item, rubric)
            case .speakingTask(let prompt, let prep, let rubric):
                AnswerText(prompt, color: LoritoColor.onInk, interaction: .standalone)
                Text("Подготовка: \(prep / 60) мин. Ответ — до 2 минут.")
                    .font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                rubricView(item, rubric)
            }
        }
        .padding(LoritoSpacing.md)
        .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
    }

    private func optionList(_ item: ExamItem, _ options: [String]) -> some View {
        VStack(spacing: LoritoSpacing.xs) {
            ForEach(options, id: \.self) { option in
                let chosen = model.attempt.answers[item.id] == option
                Button { model.answer(item, option) } label: {
                    HStack {
                        AnswerText(option, color: chosen ? LoritoColor.onHighlight : LoritoColor.onInk)
                        Spacer()
                    }
                    .padding(.horizontal, LoritoSpacing.md)
                    .frame(minHeight: LoritoLayout.minTouchTarget)
                    .background(chosen ? LoritoColor.highlight : LoritoColor.ink,
                                in: RoundedRectangle(cornerRadius: LoritoRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option)
                .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
    }

    private func rubricView(_ item: ExamItem, _ rubric: [RubricItem]) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            ForEach(rubric.indices, id: \.self) { i in
                let ticked = model.attempt.rubricTicks[item.id]?.contains(i) == true
                Button { model.toggleRubric(item, i) } label: {
                    Label(rubric[i].text, systemImage: ticked ? "checkmark.square.fill" : "square")
                        .font(LoritoFont.body).foregroundStyle(LoritoColor.onInk)
                        .frame(maxWidth: .infinity, minHeight: LoritoLayout.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            Text("Самооценка").font(LoritoFont.caption).foregroundStyle(LoritoColor.highlight)
        }
    }

    private var results: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                if let r = model.result {
                    Text(r.passed ? "Сдано" : "Пока не сдано").loritoStyle(.title).foregroundStyle(LoritoColor.highlight)
                        .accessibilityIdentifier("mock.result")
                    ForEach(model.definition.groups) { g in
                        Text("\(g.title): \(Int((r.groupPoints[g.id] ?? 0).rounded())) из \(Int(g.sections.count) * 25) (нужно \(Int(g.passPoints)))")
                            .font(LoritoFont.body).foregroundStyle(LoritoColor.onInk)
                    }
                    if !r.failingGroups.isEmpty {
                        Text("Не хватает баллов: " + r.failingGroups.compactMap { id in model.definition.groups.first { $0.id == id }?.title }.joined(separator: ", "))
                            .font(LoritoFont.bodyStrong).foregroundStyle(LoritoColor.onInk)
                    }
                    if model.items.contains(where: \.isProductive) {
                        Text("Письмо и устная часть — самооценка.").font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                    }
                    if model.attempt.expired {
                        Text("Время вышло: неотвеченные вопросы засчитаны как неверные.").font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.onInkSecondary)
                    }
                    if !model.weakestCards.isEmpty {
                        Text("Повторите карточки: " + model.weakestCards.joined(separator: ", "))
                            .font(LoritoFont.caption).foregroundStyle(LoritoColor.onInk)
                    }
                } else {
                    Text("Экзамен прерван").loritoStyle(.title).foregroundStyle(LoritoColor.onInk)
                }
                PrimaryButton("Готово", variant: .highlight, action: onClose)
                    .accessibilityIdentifier("mock.done")
            }
            .padding(LoritoSpacing.screenGutter)
        }
    }
}
