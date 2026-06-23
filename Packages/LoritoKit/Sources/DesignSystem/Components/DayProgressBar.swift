import SwiftUI

/// Segmented indicator of the day's study portion: `completed` of `total` segments filled.
public struct DayProgressBar: View {
    private let completed: Int
    private let total: Int

    public init(completed: Int, total: Int) {
        self.completed = max(0, completed)
        self.total = max(0, total)
    }

    public var body: some View {
        HStack(spacing: LoritoSpacing.xxs) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < completed ? LoritoColor.accent : LoritoColor.segmentTrack)
                    .frame(width: 18, height: 5)
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
