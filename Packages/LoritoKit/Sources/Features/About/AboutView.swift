import SwiftUI
import DesignSystem

/// One third-party attribution shown on the About / Licenses screen.
public struct LicenseEntry: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let name: String
    public let license: String
    public let detail: String
    public let url: String

    public init(name: String, license: String, detail: String, url: String) {
        self.name = name
        self.license = license
        self.detail = detail
        self.url = url
    }

    /// The bundled third-party materials that require attribution. Keep in sync
    /// with the app's dependencies (Package.swift) and bundled assets.
    public static let all: [LicenseEntry] = [
        LicenseEntry(
            name: "OpenMoji",
            license: "CC BY-SA 4.0",
            detail: "Иконки упражнений (picture-matching). All emojis designed by OpenMoji — the open-source emoji and icon project. License: CC BY-SA 4.0.",
            url: "https://openmoji.org"
        ),
        LicenseEntry(
            name: "MarkdownUI",
            license: "MIT",
            detail: "Рендеринг Markdown в карточках и упражнениях.",
            url: "https://github.com/gonzalezreal/swift-markdown-ui"
        ),
    ]
}

/// About / Licenses screen: lists third-party materials bundled in the app with
/// their license and source (satisfies the OpenMoji CC BY-SA attribution).
public struct AboutView: View {
    private let entries: [LicenseEntry]

    public init(entries: [LicenseEntry] = LicenseEntry.all) {
        self.entries = entries
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                Text("Lorito Español")
                    .font(LoritoFont.title)
                    .foregroundStyle(LoritoColor.textPrimary)
                Text("Испанский по карточкам с интервальным повторением.")
                    .font(LoritoFont.body)
                    .foregroundStyle(LoritoColor.textSecondary)

                Text("Лицензии и благодарности")
                    .font(LoritoFont.heading)
                    .foregroundStyle(LoritoColor.textPrimary)
                    .padding(.top, LoritoSpacing.sm)

                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: LoritoSpacing.xxs) {
                        HStack {
                            Text(entry.name)
                                .font(LoritoFont.body.weight(.semibold))
                                .foregroundStyle(LoritoColor.textPrimary)
                            Spacer()
                            Text(entry.license)
                                .font(LoritoFont.label)
                                .foregroundStyle(LoritoColor.accent)
                                .padding(.horizontal, LoritoSpacing.xs)
                                .padding(.vertical, LoritoSpacing.xxs)
                                .background(LoritoColor.accent.opacity(0.12), in: Capsule())
                        }
                        Text(entry.detail)
                            .font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.textSecondary)
                        Text(entry.url)
                            .font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(LoritoSpacing.sm)
                    .background(LoritoColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
                }
            }
            .padding(LoritoSpacing.lg)
            .frame(maxWidth: LoritoLayout.readingWidth)
            .frame(maxWidth: .infinity)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("О приложении")
    }
}
