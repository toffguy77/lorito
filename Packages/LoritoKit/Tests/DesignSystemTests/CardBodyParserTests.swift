import Foundation
import Testing
@testable import DesignSystem

@Suite("Card body parser")
struct CardBodyParserTests {
    @Test("Blockquote essence becomes a callout block")
    func essenceBlockquote() {
        let body = """
        > **Суть**
        > Ser выражает идентичность.

        ## Обычный заголовок
        Текст.
        """
        let blocks = CardBodyParser.parse(body)
        #expect(blocks.first == .callout(.essence, "Ser выражает идентичность."))
        // The non-callout heading + paragraph stay as a markdown span.
        if case .markdown(let md) = blocks.last {
            #expect(md.contains("## Обычный заголовок"))
        } else {
            Issue.record("expected trailing markdown block")
        }
    }

    @Test("Emoji headings map to their callout kinds")
    func headingCallouts() {
        let body = """
        ## 🔑 Ключевые моменты
        - Пункт один
        - Пункт два

        ## ⚠️ Частые ошибки
        Не путать.

        ## 💡 Полезно
        Совет.
        """
        let kinds = CardBodyParser.parse(body).compactMap { block -> CalloutKind? in
            if case .callout(let k, _) = block { return k }
            return nil
        }
        #expect(kinds == [.keyPoints, .mistakes, .useful])
    }

    @Test("Tables stay in a markdown span")
    func tablePreserved() {
        let body = """
        > **Суть**
        > Алфавит.

        | A | B |
        |---|---|
        | a | b |
        """
        let blocks = CardBodyParser.parse(body)
        let markdownText = blocks.compactMap { block -> String? in
            if case .markdown(let md) = block { return md }
            return nil
        }.joined(separator: "\n")
        #expect(markdownText.contains("| A | B |"))
    }

    @Test("Title keyword matching ignores emoji and punctuation")
    func keywordMatching() {
        #expect(CardBodyParser.calloutKind(matching: "🔑 Ключевые моменты") == .keyPoints)
        #expect(CardBodyParser.calloutKind(matching: "⚠️ Частая ошибка") == .mistakes)
        #expect(CardBodyParser.calloutKind(matching: "Примеры") == nil)
    }

    @Test("Unrecognized content round-trips as a single markdown block")
    func fallback() {
        let body = "Просто параграф без секций."
        #expect(CardBodyParser.parse(body) == [.markdown("Просто параграф без секций.")])
    }
}

@Suite("First mistake")
struct FirstMistakeTests {
    @Test("First bullet of the mistakes section, heading or blockquote form")
    func firstBullet() {
        let heading = "> **Суть**\n> X\n\n## ⚠️ Частые ошибки\n- **Один**: *el*.\n- Два.\n"
        #expect(CardBodyParser.firstMistake(in: heading) == "**Один**: *el*.")
        let quote = "> **Частые ошибки**\n> * Первый\n> * Второй\n"
        #expect(CardBodyParser.firstMistake(in: quote) == "Первый")
    }

    @Test("Paragraph mistakes use the first line; none → nil")
    func paragraphAndNone() {
        #expect(CardBodyParser.firstMistake(in: "## Частые ошибки\nНе путать.\nЕщё.") == "Не путать.")
        #expect(CardBodyParser.firstMistake(in: "> **Суть**\n> X") == nil)
    }
}

@Suite("Recall prompt runs")
struct RecallPromptRunsTests {
    @Test("Bold is the question, emphasis is Spanish, the rest plain")
    func runs() {
        let runs = RecallPromptView.runs("**¿el или la?** *problema, mano*")
        #expect(runs.map(\.voice) == [.question, .plain, .spanish])
        #expect(runs.last?.text == "problema, mano")
    }

    @Test("Plain prompt stays one plain run")
    func plain() {
        let runs = RecallPromptView.runs("Вспомните главное: «Род»")
        #expect(runs.count == 1 && runs[0].voice == .plain)
    }
}

@Suite("Activity heatmap layout")
struct ActivityHeatmapLayoutTests {
    @Test("Rows are Monday…Sunday; columns hold whole weeks, oldest first")
    func layout() {
        let cal = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
        let today = cal.date(from: DateComponents(year: 2026, month: 10, day: 27))!   // Tuesday
        let days = (0..<84).reversed().map { offset in
            HeatmapDay(day: cal.date(byAdding: .day, value: -offset, to: today)!, count: 0, bucket: 0)
        }
        let columns = ActivityHeatmap.columns(days, calendar: cal)
        #expect(columns.allSatisfy { $0.count == 7 })
        #expect(columns.flatMap { $0 }.compactMap { $0 }.count == 84)
        #expect(ActivityHeatmap.row(of: today, calendar: cal) == 1)                  // Tuesday
        #expect(columns.last?[1]?.day == today)                                      // today in its weekday row
        #expect(columns.last![2] == nil)                                               // future slots empty
    }
}
