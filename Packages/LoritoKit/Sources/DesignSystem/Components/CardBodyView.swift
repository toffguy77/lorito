import SwiftUI
import MarkdownUI

/// Renders a card's Markdown body (supports tables and the callout blockquotes
/// produced by the content pipeline).
public struct CardBodyView: View {
    private let markdown: String

    public init(_ markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        Markdown(markdown)
            .markdownTheme(.gitHub)
            .textSelection(.enabled)
    }
}

#Preview {
    ScrollView {
        CardBodyView(
            """
            > **Суть**
            > *Ser* выражает идентичность и неизменные свойства.

            ## Спряжение
            | Лицо | Форма |
            |------|-------|
            | yo | soy |
            | tú | eres |
            """
        )
        .padding()
    }
    .background(LoritoColor.surface)
}
