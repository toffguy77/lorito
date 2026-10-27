import SwiftUI

/// Per-card outcome shown in the session progress bar.
public enum SessionSegment: Equatable, Sendable {
    case pending
    case current
    /// Graded and remembered.
    case passed
    /// Graded "Опять" / answered wrong.
    case missed
}

/// Segmented session progress on ink: one segment per card colored by its
/// outcome. Long sessions (more cards than fit legibly) collapse to a single
/// continuous bar.
public struct SessionProgressBar: View {
    private let segments: [SessionSegment]
    /// Above this many cards the bar is continuous.
    public static var maxSegments: Int { 24 }

    public init(segments: [SessionSegment]) {
        self.segments = segments
    }

    /// Convenience when only the position is known: cards before `current` are
    /// passed, the rest pending.
    public init(current: Int, total: Int) {
        self.segments = Self.segments(current: current, total: total)
    }

    public static func segments(current: Int, total: Int) -> [SessionSegment] {
        (0..<max(total, 0)).map { i in
            i < current ? .passed : (i == current ? .current : .pending)
        }
    }

    private var doneCount: Int {
        segments.filter { $0 == .passed || $0 == .missed }.count
    }

    public var body: some View {
        Group {
            if segments.count > Self.maxSegments {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(LoritoColor.inkTrack)
                        Capsule()
                            .fill(LoritoColor.highlight)
                            .frame(width: proxy.size.width * CGFloat(doneCount) / CGFloat(max(segments.count, 1)))
                    }
                }
            } else {
                HStack(spacing: 3) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        Capsule().fill(color(segment))
                    }
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Прогресс сессии")
        .accessibilityValue("\(doneCount) из \(segments.count)")
    }

    private func color(_ segment: SessionSegment) -> Color {
        switch segment {
        case .pending: return LoritoColor.inkTrack
        case .current: return LoritoColor.onInk
        case .passed: return LoritoColor.highlight
        case .missed: return LoritoColor.danger
        }
    }
}

#Preview {
    VStack(spacing: LoritoSpacing.md) {
        SessionProgressBar(segments: [.passed, .passed, .missed, .current, .pending, .pending])
        SessionProgressBar(current: 13, total: 40)
    }
    .padding()
    .background(LoritoColor.ink)
}
