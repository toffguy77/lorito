import Testing
import Content
import DesignSystem

/// Verifies the shared Markdown parser against the real bundled cards (task 1.4):
/// every body parses without loss, tables survive as markdown, and all four
/// callout kinds appear across the corpus.
@Suite("Card body parser — bundled corpus")
struct CardBodyCorpusTests {
    @Test("All bundled cards parse, with tables and every callout kind present")
    func corpus() throws {
        let catalog = try ContentLoader.loadCatalog()
        #expect(!catalog.cards.isEmpty)

        var seenCallouts: Set<CalloutKind> = []
        var sawTable = false

        for card in catalog.cards {
            let blocks = CardBodyParser.parse(card.body)
            // Parsing never drops content: a non-empty body yields at least one block.
            if !card.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                #expect(!blocks.isEmpty)
            }
            for block in blocks {
                switch block {
                case .callout(let kind, _):
                    seenCallouts.insert(kind)
                case .markdown(let md):
                    if md.contains("|") && md.contains("---") { sawTable = true }
                }
            }
        }

        // The corpus exercises tables and every callout variant.
        #expect(sawTable)
        #expect(seenCallouts.contains(.essence))
        #expect(seenCallouts.contains(.keyPoints))
        #expect(seenCallouts.contains(.mistakes))
        #expect(seenCallouts.contains(.useful))
    }
}
