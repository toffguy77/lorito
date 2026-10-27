import SwiftUI
import Domain
import DesignSystem

/// What a recap / milestone share image may show: brand mark, numbers or the
/// level, month and year — never a name, account or device data.
struct ShareCardContent: Equatable, Sendable {
    let headline: String
    let lines: [String]
    let monthYear: String

    static func milestone(_ level: CEFRLevel, date: Date) -> ShareCardContent {
        ShareCardContent(headline: "\(level.rawValue) закрыт",
                         lines: ["уровень пройден в Lorito", "все правила \(level.rawValue) — в долгой памяти"],
                         monthYear: monthYear(date))
    }

    static func recap(_ r: WeeklyRecap) -> ShareCardContent {
        ShareCardContent(headline: "Моя неделя",
                         lines: ["\(r.daysStudied) \(RussianPlural.form(r.daysStudied, one: "день", few: "дня", many: "дней")) занятий",
                                 "\(r.newRules) \(RussianPlural.form(r.newRules, one: "новое правило", few: "новых правила", many: "новых правил"))",
                                 "\(r.longTerm) в долгой памяти"],
                         monthYear: monthYear(r.weekStart))
    }

    static func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return f.string(from: date)
    }
}

/// 9:16 share card for a weekly recap or a closed level.
struct RecapShareCard: View {
    let content: ShareCardContent
    static let size = CGSize(width: 360, height: 640)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("¡Lorito!")
                .font(LoritoTextStyle.display.sized(40).font)
                .foregroundStyle(LoritoColor.highlight)
            Spacer()
            Text(content.headline)
                .font(LoritoTextStyle.display.sized(52).font)
                .foregroundStyle(LoritoColor.highlight)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
            ForEach(content.lines, id: \.self) { line in
                Text(line)
                    .font(LoritoTextStyle.bodyStrong.sized(22).font)
                    .foregroundStyle(LoritoColor.onInk)
            }
            Spacer()
            Text(content.monthYear)
                .font(LoritoTextStyle.bodyStrong.sized(18).font)
                .foregroundStyle(LoritoColor.onInkSecondary)
        }
        .padding(36)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .leading)
        .background(alignment: .topTrailing) {
            Text("¡")
                .font(LoritoTextStyle.display.sized(420).font)
                .foregroundStyle(LoritoColor.inkRaised)
                .offset(x: 60, y: -40)
        }
        .background(LoritoColor.ink)
        .environment(\.dynamicTypeSize, .large)
    }

    @MainActor
    static func render(_ content: ShareCardContent) -> Image? {
        let renderer = ImageRenderer(content: RecapShareCard(content: content))
        renderer.scale = 3
        #if canImport(UIKit)
        return renderer.uiImage.map(Image.init(uiImage:))
        #else
        return renderer.nsImage.map(Image.init(nsImage:))
        #endif
    }
}
