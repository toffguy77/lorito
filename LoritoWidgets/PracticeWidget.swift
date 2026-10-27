import SwiftUI
import WidgetKit
import AppIntents
import Domain
import DesignSystem
import WidgetSupport

/// Answer a practice question from the widget. Practice only: stores the
/// choice in the App Group defaults — never touches reviews or study events.
struct AnswerQuestionIntent: AppIntent {
    static let title: LocalizedStringResource = "Ответить"
    static let isDiscoverable = false

    @Parameter(title: "Вариант") var option: String

    init() {}
    init(option: String) { self.option = option }

    func perform() async throws -> some IntentResult {
        PracticeAnswerStore.shared?.choose(option, on: Date())
        return .result()
    }
}

/// Move to the next question of the day.
struct NextQuestionIntent: AppIntent {
    static let title: LocalizedStringResource = "Дальше"
    static let isDiscoverable = false

    @Parameter(title: "Количество") var count: Int

    init() {}
    init(count: Int) { self.count = count }

    func perform() async throws -> some IntentResult {
        PracticeAnswerStore.shared?.next(on: Date(), count: count)
        return .result()
    }
}

/// Medium: "Вспомни без приложения" — one multiple-choice question answered in place.
struct PracticeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "lorito.practice", provider: SnapshotProvider()) { entry in
            PracticeWidgetView(entry: entry)
                .containerBackground(LoritoColor.ink, for: .widget)
                .widgetURL(LoritoDeepLink.today)
        }
        .configurationDisplayName("Вспомни")
        .description("Вопрос из упражнений — ответ прямо в виджете.")
        .supportedFamilies([.systemMedium])
    }
}

struct PracticeWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let questions = entry.snapshot?.questions, !questions.isEmpty {
            let state = PracticeAnswerStore.shared?.state(for: entry.date) ?? .init(index: 0, chosen: nil)
            let question = questions[state.index % questions.count]
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Вспомни без приложения").loritoStyle(.label).foregroundStyle(LoritoColor.highlight)
                    Spacer()
                    Text("\(state.index % questions.count + 1) из \(questions.count)")
                        .font(LoritoFont.caption).foregroundStyle(LoritoColor.onInkSecondary)
                }
                Text(prompt(question.prompt))
                    .font(LoritoFont.bodyStrong)
                    .foregroundStyle(LoritoColor.onInk)
                    .lineLimit(2)
                if let chosen = state.chosen {
                    HStack {
                        let correct = chosen == question.answer
                        Label(correct ? "Верно" : "Правильно: \(question.answer)",
                              systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(LoritoFont.bodyStrong)
                            .foregroundStyle(correct ? LoritoColor.highlight : LoritoColor.danger)
                        Spacer()
                        Button(intent: NextQuestionIntent(count: questions.count)) {
                            Text("Дальше").font(LoritoFont.bodyStrong)
                        }
                        .tint(LoritoColor.highlight)
                    }
                } else {
                    HStack(spacing: 8) {
                        ForEach(question.options.prefix(4), id: \.self) { option in
                            Button(intent: AnswerQuestionIntent(option: option)) {
                                AnswerText(option, spanishSize: 20, color: LoritoColor.onInk)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 8)
                            .background(LoritoColor.inkRaised, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        } else {
            OpenLoritoView()
        }
    }

    /// Prompt Markdown as styled text (emphasis → Spanish voice).
    private func prompt(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(markdown)
    }
}
