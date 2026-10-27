import SwiftUI

/// Lays card blocks out in two columns at regular width: each block, in order,
/// goes whole into the currently shorter column. When the body fits the
/// available height in one column (or has a single block) it stays one
/// centered column instead.
public struct BalancedColumnsLayout: Layout {
    private let spacing: CGFloat
    private let columnSpacing: CGFloat
    private let maxColumnWidth: CGFloat
    private let singleColumnWidth: CGFloat
    private let availableHeight: CGFloat

    public init(
        spacing: CGFloat = LoritoSpacing.md,
        columnSpacing: CGFloat = LoritoSpacing.lg,
        maxColumnWidth: CGFloat = LoritoLayout.readingWidth / 2 + LoritoSpacing.screenGutter,
        singleColumnWidth: CGFloat = LoritoLayout.readingWidth,
        availableHeight: CGFloat
    ) {
        self.spacing = spacing
        self.columnSpacing = columnSpacing
        self.maxColumnWidth = maxColumnWidth
        self.singleColumnWidth = singleColumnWidth
        self.availableHeight = availableHeight
    }

    // MARK: Pure rules (tested)

    /// Column index per block and the resulting column heights.
    nonisolated static func assign(heights: [CGFloat], spacing: CGFloat) -> (columns: [Int], columnHeights: [CGFloat]) {
        var columnHeights: [CGFloat] = [0, 0]
        var counts = [0, 0]
        var columns: [Int] = []
        for height in heights {
            let col = columnHeights[1] < columnHeights[0] ? 1 : 0
            columnHeights[col] += (counts[col] > 0 ? spacing : 0) + height
            counts[col] += 1
            columns.append(col)
        }
        return (columns, columnHeights)
    }

    nonisolated static func usesSingleColumn(totalHeight: CGFloat, availableHeight: CGFloat, count: Int) -> Bool {
        count < 2 || totalHeight <= availableHeight
    }

    // MARK: Layout

    private struct Arrangement {
        var single: Bool
        var width: CGFloat
        var columnWidth: CGFloat
        var columns: [Int]
        var heights: [CGFloat]
        var size: CGSize
    }

    private func arrange(_ proposal: ProposedViewSize, _ subviews: Subviews) -> Arrangement {
        let width = proposal.width ?? singleColumnWidth
        let oneWidth = min(width, singleColumnWidth)
        let oneHeights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: oneWidth, height: nil)).height }
        let total = oneHeights.reduce(0, +) + spacing * CGFloat(max(subviews.count - 1, 0))
        if Self.usesSingleColumn(totalHeight: total, availableHeight: availableHeight, count: subviews.count) {
            return Arrangement(single: true, width: width, columnWidth: oneWidth, columns: [],
                               heights: oneHeights, size: CGSize(width: width, height: total))
        }
        let columnWidth = min((width - columnSpacing) / 2, maxColumnWidth)
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height }
        let result = Self.assign(heights: heights, spacing: spacing)
        return Arrangement(single: false, width: width, columnWidth: columnWidth, columns: result.columns,
                           heights: heights, size: CGSize(width: width, height: result.columnHeights.max() ?? 0))
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal, subviews).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let a = arrange(ProposedViewSize(width: bounds.width, height: bounds.height), subviews)
        if a.single {
            let x = bounds.minX + (bounds.width - a.columnWidth) / 2
            var y = bounds.minY
            for (i, subview) in subviews.enumerated() {
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                              proposal: ProposedViewSize(width: a.columnWidth, height: a.heights[i]))
                y += a.heights[i] + spacing
            }
            return
        }
        let used = a.columnWidth * 2 + columnSpacing
        let left = bounds.minX + (bounds.width - used) / 2
        var y: [CGFloat] = [bounds.minY, bounds.minY]
        for (i, subview) in subviews.enumerated() {
            let col = a.columns[i]
            let x = left + CGFloat(col) * (a.columnWidth + columnSpacing)
            subview.place(at: CGPoint(x: x, y: y[col]), anchor: .topLeading,
                          proposal: ProposedViewSize(width: a.columnWidth, height: a.heights[i]))
            y[col] += a.heights[i] + spacing
        }
    }
}
