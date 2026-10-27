import SwiftUI
import Domain
import DesignSystem

/// The 9:16 "Stories" card shared from the session summary: brand mark,
/// streak and a fixed Spanish proverb. No name or other personal data.
struct StreakShareCard: View {
    let streak: Int

    static let proverb = "Poco a poco se va lejos."
    /// Logical size; rendered at 3× → 1080 × 1920 px.
    static let size = CGSize(width: 360, height: 640)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("¡Lorito!")
                .font(LoritoTextStyle.display.sized(40).font)
                .foregroundStyle(LoritoColor.highlight)
            Spacer()
            Text("\(streak)")
                .font(LoritoTextStyle.number.sized(140).font)
                .foregroundStyle(LoritoColor.highlight)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("\(RussianPlural.form(streak, one: "день", few: "дня", many: "дней")) испанского\nбез пропусков")
                .font(LoritoTextStyle.bodyStrong.sized(22).font)
                .foregroundStyle(LoritoColor.onInk)
            Spacer()
            SpanishText(Self.proverb, size: .custom(26), color: LoritoColor.onInkSecondary)
        }
        .padding(36)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .leading)
        .background(alignment: .topTrailing) {
            Text("¿")
                .font(LoritoTextStyle.display.sized(420).font)
                .foregroundStyle(LoritoColor.inkRaised)
                .offset(x: 60, y: -40)
        }
        .background(LoritoColor.ink)
        .environment(\.dynamicTypeSize, .large)   // fixed layout regardless of the user's text size
    }

    /// Renders the card to an image on device.
    @MainActor
    static func render(streak: Int) -> Image? {
        let renderer = ImageRenderer(content: StreakShareCard(streak: streak))
        renderer.scale = 3
        #if canImport(UIKit)
        return renderer.uiImage.map(Image.init(uiImage:))
        #else
        return renderer.nsImage.map(Image.init(nsImage:))
        #endif
    }
}
