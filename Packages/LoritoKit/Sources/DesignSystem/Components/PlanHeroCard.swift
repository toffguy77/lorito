import SwiftUI

/// The ink hero card on Today: a big number, a three-segment composition bar,
/// a counts row, and a slot for the call to action.
public struct PlanHeroCard<CTA: View>: View {
    /// One part of the plan (e.g. "8 повторить").
    public struct Part: Identifiable, Sendable {
        public enum Tone: Sendable { case highlight, accent, light }

        public let id: String
        public let count: Int
        public let label: String
        public let tone: Tone

        public init(count: Int, label: String, tone: Tone) {
            self.id = label
            self.count = count
            self.label = label
            self.tone = tone
        }

        var color: Color {
            switch tone {
            case .highlight: return LoritoColor.highlight
            case .accent: return LoritoColor.accent
            case .light: return LoritoColor.onInk
            }
        }
    }

    private let total: Int
    private let caption: String
    private let trailing: String?
    private let parts: [Part]
    private let showsCounts: Bool
    private let cta: CTA

    public init(
        total: Int,
        caption: String,
        trailing: String? = nil,
        parts: [Part],
        showsCounts: Bool = true,
        @ViewBuilder cta: () -> CTA
    ) {
        self.showsCounts = showsCounts
        self.total = total
        self.caption = caption
        self.trailing = trailing
        self.parts = parts
        self.cta = cta()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                    Text("\(total)")
                        .loritoStyle(.number)
                        .foregroundStyle(LoritoColor.highlight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(caption)
                        .font(LoritoFont.body)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                }
                Spacer(minLength: LoritoSpacing.sm)
                if let trailing {
                    Text(trailing)
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .accessibilityElement(children: .combine)

            compositionBar

            if showsCounts {
                countsRow
            }

            cta
        }
        .padding(LoritoSpacing.lg - 2)
        .background(LoritoColor.ink, in: RoundedRectangle(cornerRadius: LoritoRadius.xl - 4, style: .continuous))
    }

    private var countsRow: some View {
        HStack(alignment: .top, spacing: LoritoSpacing.xs) {
            ForEach(parts) { part in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(part.count)")
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(LoritoColor.onInk)
                    Text(part.label)
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.onInkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Segments proportional to each part's count; hidden when there is nothing.
    @ViewBuilder
    private var compositionBar: some View {
        let nonEmpty = parts.filter { $0.count > 0 }
        let sum = nonEmpty.reduce(0) { $0 + $1.count }
        if sum > 0 {
            GeometryReader { proxy in
                let spacing: CGFloat = 4
                let available = proxy.size.width - spacing * CGFloat(nonEmpty.count - 1)
                HStack(spacing: spacing) {
                    ForEach(nonEmpty) { part in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(part.color)
                            .frame(width: max(6, available * CGFloat(part.count) / CGFloat(sum)))
                    }
                }
            }
            .frame(height: 10)
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    PlanHeroCard(
        total: 12,
        caption: "карточек в плане дня",
        parts: [
            .init(count: 8, label: "повторить", tone: .highlight),
            .init(count: 4, label: "новых", tone: .accent),
        ]
    ) {
        PrimaryButton("Начать", variant: .highlight) {}
    }
    .padding()
    .background(LoritoColor.surface)
}
