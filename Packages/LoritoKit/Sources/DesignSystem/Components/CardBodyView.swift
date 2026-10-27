import SwiftUI
import MarkdownUI

/// The surface a card body is rendered on; picks the text colors of the theme.
public enum CardBodyTone: Sendable {
    /// Light/dark page surfaces (`surfaceRaised`, `surfaceSunken`).
    case surface
    /// Focus surfaces (`ink`).
    case ink
}

/// Renders a card's Markdown body (supports tables and the callout blockquotes
/// produced by the content pipeline). Russian text renders in Onest; Markdown
/// emphasis (`*el libro*`) — the content's marker for Spanish — renders in the
/// Spanish voice (`spanishInline` + `accent`).
public struct CardBodyView: View {
    private let markdown: String
    private let tone: CardBodyTone
    /// MarkdownUI uses fixed-size fonts, so scale the base sizes here.
    @ScaledMetric(relativeTo: .body) private var bodySize = LoritoTextStyle.body.size
    @ScaledMetric(relativeTo: .body) private var spanishSize = LoritoTextStyle.spanishInline.size

    public init(_ markdown: String, tone: CardBodyTone = .surface) {
        self.markdown = markdown
        self.tone = tone
    }

    public var body: some View {
        Markdown(markdown)
            .markdownTheme(.lorito(tone: tone, bodySize: bodySize, spanishSize: spanishSize))
            .textSelection(.enabled)
    }
}

extension Theme {
    /// The Plumaje Markdown theme.
    @MainActor static func lorito(tone: CardBodyTone, bodySize: CGFloat, spanishSize: CGFloat) -> Theme {
        let text = tone == .ink ? LoritoColor.onInk : LoritoColor.textPrimary
        let secondary = tone == .ink ? LoritoColor.onInkSecondary : LoritoColor.textSecondary
        let spanish = tone == .ink ? LoritoColor.highlight : LoritoColor.accent
        let rule = tone == .ink ? LoritoColor.inkTrack : LoritoColor.separator
        let sunken = tone == .ink ? LoritoColor.inkRaised : LoritoColor.surfaceSunken

        return Theme()
            .text {
                FontFamily(.custom(LoritoTextStyle.body.postScriptName))
                FontSize(bodySize)
                ForegroundColor(text)
            }
            .emphasis {
                FontFamily(.custom(LoritoTextStyle.spanishInline.postScriptName))
                FontStyle(.normal)
                FontSize(spanishSize)
                ForegroundColor(spanish)
            }
            .strong {
                FontFamily(.custom(LoritoTextStyle.bodyStrong.postScriptName))
            }
            .link {
                ForegroundColor(spanish)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.88))
                BackgroundColor(sunken)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: 20, bottom: 10)
                    .markdownTextStyle {
                        FontFamily(.custom(LoritoTextStyle.heading.postScriptName))
                        FontSize(.em(1.35))
                    }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: 20, bottom: 10)
                    .markdownTextStyle {
                        FontFamily(.custom(LoritoTextStyle.heading.postScriptName))
                        FontSize(.em(1.15))
                    }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: 16, bottom: 8)
                    .markdownTextStyle {
                        FontFamily(.custom(LoritoTextStyle.bodyStrong.postScriptName))
                        FontSize(.em(1.05))
                    }
            }
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.2))
                    .markdownMargin(top: 0, bottom: 12)
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(rule)
                        .frame(width: 3)
                    configuration.label
                        .markdownTextStyle { ForegroundColor(secondary) }
                        .padding(.horizontal, 12)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .listItem { configuration in
                configuration.label.markdownMargin(top: .em(0.25))
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(.insideHorizontalBorders, color: rule))
                    .markdownMargin(top: 0, bottom: 12)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontFamily(.custom(LoritoTextStyle.bodyStrong.postScriptName))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .padding(.trailing, 12)
            }
            .thematicBreak {
                Rectangle().fill(rule).frame(height: 1).markdownMargin(top: 16, bottom: 16)
            }
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
            | yo | *soy* |
            | tú | *eres* |
            """
        )
        .padding()
    }
    .background(LoritoColor.surface)
}
