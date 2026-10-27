import SwiftUI

/// The recall question on a study card's front: inline Markdown where `**bold**`
/// is the question (Unbounded), `*emphasis*` is Spanish (Spanish voice, accent,
/// tagged `es-ES`), and plain text is Russian (Onest).
public struct RecallPromptView: View {
    private let markdown: String

    public init(_ markdown: String) {
        self.markdown = markdown
    }

    /// A run of the prompt and how it is voiced.
    enum Voice: Equatable { case question, spanish, plain }

    /// Split inline Markdown into voiced runs (pure; falls back to plain text).
    nonisolated static func runs(_ markdown: String) -> [(text: String, voice: Voice)] {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let parsed = try? AttributedString(markdown: markdown, options: options) else {
            return [(markdown, .plain)]
        }
        return parsed.runs.map { run in
            let text = String(parsed[run.range].characters)
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.emphasized) { return (text, .spanish) }
            if intent.contains(.stronglyEmphasized) { return (text, .question) }
            return (text, .plain)
        }
    }

    public var body: some View {
        Self.runs(markdown).reduce(Text("")) { partial, run in
            partial + text(for: run)
        }
        .foregroundStyle(LoritoColor.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func text(for run: (text: String, voice: Voice)) -> Text {
        switch run.voice {
        case .question:
            return Text(run.text).font(LoritoTextStyle.title.font).tracking(LoritoTextStyle.title.tracking)
        case .spanish:
            return Text(SpanishText.attributed(run.text))
                .font(LoritoTextStyle.spanish.sized(32).font)
                .foregroundStyle(LoritoColor.accent)
        case .plain:
            return Text(run.text).font(LoritoTextStyle.heading.font)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        RecallPromptView("**¿el или la?** *problema, mano, canción, agua*")
        RecallPromptView("Вспомните главное: «Род существительных»")
    }
    .padding()
    .background(LoritoColor.surfaceRaised)
}
