import SwiftUI
import Domain

/// Renders a card body as a sequence of Markdown spans and typed callout blocks.
/// Shared by the study session and the catalog card reader so a card looks
/// identical in both.
public struct CardContentView: View {
    private let source: String
    private let tone: CardBodyTone
    /// When set, blocks balance across two columns unless they fit this height.
    private let twoColumnsAbove: CGFloat?

    public init(_ body: String, tone: CardBodyTone = .surface, twoColumnsAbove: CGFloat? = nil) {
        self.source = body
        self.tone = tone
        self.twoColumnsAbove = twoColumnsAbove
    }

    /// The learner's regional variant (set at the root from settings).
    @Environment(\.spanishVariant) private var variant

    private var blocks: [CardBlock] { CardBodyParser.parse(source, variant: variant) }

    public var body: some View {
        content.modifier(VariantAlternativesAction(alternatives: VariantMarkup.alternatives(in: source, for: variant)))
    }

    @ViewBuilder private var content: some View {
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
            case .variantNote(let title, let md):
                VariantNote(title: title, markdown: md, tone: tone)
            }
        }
    }
}

public extension EnvironmentValues {
    /// The learner's regional variant for card rendering (regional-variants).
    @Entry var spanishVariant: SpanishVariant = .spain
}

/// Another variant's block, collapsed under «В Испании» etc.
struct VariantNote: View {
    let title: String
    let markdown: String
    let tone: CardBodyTone
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            CardBodyView(markdown, tone: tone)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, LoritoSpacing.xs)
        } label: {
            Text(title)
                .loritoStyle(.label)
                .foregroundStyle(tone == .ink ? LoritoColor.onInkSecondary : LoritoColor.textSecondary)
        }
        .tint(tone == .ink ? LoritoColor.onInkSecondary : LoritoColor.textSecondary)
        .accessibilityIdentifier("variantNote")
    }
}

/// «Варианты» on inline alternatives: lists every form with its region.
private struct VariantAlternativesAction: ViewModifier {
    let alternatives: [String: [VariantForm]]

    func body(content: Content) -> some View {
        if alternatives.isEmpty {
            content
        } else {
            content.spanishSpanAction(SpanishSpanAction(
                id: "variants", title: "Варианты", systemImage: "globe",
                appliesTo: { alternatives[$0] != nil },
                sheet: { span, dismiss in
                    alternatives[span].map { AnyView(VariantFormsSheet(forms: $0, dismiss: dismiss)) }
                },
                perform: { _ in }))
        }
    }
}

struct VariantFormsSheet: View {
    let forms: [VariantForm]
    let dismiss: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            List(forms, id: \.variant) { form in
                VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
                    SpanishText(form.text, size: .inline, interaction: .none)
                    Text(form.variant.regionName)
                        .loritoStyle(.caption)
                        .foregroundStyle(LoritoColor.textSecondary)
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle("Варианты")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
        .accessibilityIdentifier("variantFormsSheet")
    }
}
