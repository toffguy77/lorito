import SwiftUI

/// The raised surface that wraps a study card's content (chip, title, body).
public struct StudyCardContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.md) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LoritoSpacing.lg)
        .padding(.vertical, LoritoSpacing.lg + 2)
        .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.xl, style: .continuous))
    }
}

#Preview {
    StudyCardContainer {
        LevelChip(level: "A1", theme: "Verbos")
        Text("El verbo ser")
            .loritoStyle(.title)
            .foregroundStyle(LoritoColor.textPrimary)
        CalloutBlock(.essence, "Ser выражает идентичность и неизменные свойства.")
    }
    .padding()
    .background(LoritoColor.ink)
}
