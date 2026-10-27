import SwiftUI

/// Segmented indicator of the day's study portion: `completed` of `total` segments filled.
public struct DayProgressBar: View {
    public enum Tone: Sendable { case surface, ink }

    private let completed: Int
    private let total: Int
    private let tone: Tone

    public init(completed: Int, total: Int, tone: Tone = .surface) {
        self.completed = max(0, completed)
        self.total = max(0, total)
        self.tone = tone
    }

    private var fill: Color { tone == .ink ? LoritoColor.highlight : LoritoColor.accent }
    private var track: Color { tone == .ink ? LoritoColor.inkTrack : LoritoColor.surfaceSunken }

    public var body: some View {
        HStack(spacing: LoritoSpacing.xxs) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < completed ? fill : track)
                    .frame(height: 6)
                    .frame(maxWidth: 24)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Прогресс дня")
        .accessibilityValue("\(completed) из \(total)")
    }
}

#Preview {
    DayProgressBar(completed: 3, total: 8)
        .padding()
        .background(LoritoColor.surface)
}
