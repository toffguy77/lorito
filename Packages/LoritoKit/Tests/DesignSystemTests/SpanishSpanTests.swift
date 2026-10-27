import Foundation
import Testing
@testable import DesignSystem

@Suite("Spanish span links")
struct SpanishSpanLinkTests {
    @Test("Spanish emphasis becomes a lorito-es span link; numbers and quotes stay plain")
    func transform() {
        let md = "Слово *el problema* и число *1.000,50*, цитата *«…»*."
        let out = SpanishSpans.link(md)
        #expect(out.contains("[*el problema*](lorito-es://span?text=el%20problema)"))
        #expect(out.contains("*1.000,50*"))
        #expect(!out.contains("text=1.000"))
        #expect(out.contains("*«…»*"))
    }

    @Test("Bold, code, existing links and tables keep their syntax")
    func untouched() {
        let md = "**Важно**: `*code*`, [*ссылка*](https://x.y) и | *la casa* |"
        let out = SpanishSpans.link(md)
        #expect(out.contains("**Важно**"))
        #expect(out.contains("`*code*`"))
        #expect(out.contains("[*ссылка*](https://x.y)"))
        #expect(out.contains("[*la casa*](lorito-es://span?text=la%20casa)"))
    }

    @Test("Spans of a block in order, without duplicates")
    func spans() {
        #expect(SpanishSpans.spans(in: "*hola* y *adiós*, otra vez *hola*; *123*") == ["hola", "adiós"])
    }

    @Test("URL round-trip")
    func url() {
        let url = SpanishSpans.url(for: "¿qué tal?")
        #expect(SpanishSpans.text(from: url) == "¿qué tal?")
        #expect(SpanishSpans.text(from: URL(string: "https://example.com")!) == nil)
    }

    @Test("A span needs a Latin letter")
    func latin() {
        #expect(SpanishSpans.isSpanish("ñ"))
        #expect(SpanishSpans.isSpanish("el agua"))
        #expect(!SpanishSpans.isSpanish("1.000,50"))
        #expect(!SpanishSpans.isSpanish("«…»"))
        #expect(!SpanishSpans.isSpanish("проблема"))
    }
}

@Suite("Spanish span actions")
@MainActor
struct SpanishSpanActionsTests {
    @Test("Menu shows only registered items; tap is a no-op without a primary action")
    func registry() {
        var actions = SpanishSpanActions()
        #expect(actions.menuItems.isEmpty)
        #expect(actions.performPrimary("hola") == false)      // nothing happens, no error

        var spoken: [String] = []
        actions.register(SpanishSpanAction(id: "speak", title: "Произнести", systemImage: "speaker.wave.2",
                                           isPrimary: true) { spoken.append($0) })
        #expect(actions.menuItems.map(\.title) == ["Произнести"])
        #expect(actions.performPrimary("hola"))
        #expect(spoken == ["hola"])
    }

    @Test("Registering the same id twice keeps one item")
    func dedupe() {
        var actions = SpanishSpanActions()
        let a = SpanishSpanAction(id: "words", title: "В мои слова", systemImage: "plus") { _ in }
        actions.register(a); actions.register(a)
        #expect(actions.menuItems.count == 1)
    }
}
