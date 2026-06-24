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
