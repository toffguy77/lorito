import SwiftUI
import Domain

/// Renders a card body as a sequence of Markdown spans and typed callout blocks.
/// Shared by the study session and the catalog card reader so a card looks
/// identical in both.
public struct CardContentView: View {
    private let blocks: [CardBlock]
    private let tone: CardBodyTone
    /// When set, blocks balance across two columns unless they fit this height.
    private let twoColumnsAbove: CGFloat?

    public init(_ body: String, tone: CardBodyTone = .surface, twoColumnsAbove: CGFloat? = nil) {
        self.blocks = CardBodyParser.parse(body)
        self.tone = tone
        self.twoColumnsAbove = twoColumnsAbove
    }

    public var body: some View {
        if let height = twoColumnsAbove {
            BalancedColumnsLayout(availableHeight: height) { blockViews }
        } else {
            VStack(alignment: .leading, spacing: LoritoSpacing.md) { blockViews }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var blockViews: some View {
        ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
            switch block {
            case .markdown(let md):
                CardBodyView(md, tone: tone)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .callout(let kind, let md):
                CalloutBlock(kind) { CardBodyView(md, tone: kind.isOnInk ? .ink : .surface) }
            }
        }
    }
}
