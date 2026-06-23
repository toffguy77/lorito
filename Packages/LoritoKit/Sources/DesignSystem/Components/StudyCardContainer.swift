import SwiftUI

/// The elevated surface that wraps a study card's content (chip, title, body).
public struct StudyCardContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LoritoSpacing.lg)
        .background(LoritoColor.surface, in: RoundedRectangle(cornerRadius: LoritoRadius.lg))
        .loritoElevation()
    }
}

#Preview {
    StudyCardContainer {
        LevelChip(level: "A1", theme: "Verbos")
        Text("El verbo ser")
            .font(LoritoFont.title)
            .foregroundStyle(LoritoColor.textPrimary)
        CalloutBlock(.essence, "Ser выражает идентичность и неизменные свойства.")
    }
    .padding()
    .background(LoritoColor.surfaceSecondary)
}
