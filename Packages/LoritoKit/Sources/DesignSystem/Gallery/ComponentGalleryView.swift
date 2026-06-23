import SwiftUI

/// Developer-facing gallery that renders every design-system component.
/// Use the scheme picker to verify light and dark appearances.
public struct ComponentGalleryView: View {
    @State private var scheme: SchemeChoice = .system

    public init() {}

    enum SchemeChoice: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "Системная"
            case .light: return "Светлая"
            case .dark: return "Тёмная"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LoritoSpacing.lg) {
                Picker("Тема", selection: $scheme) {
                    ForEach(SchemeChoice.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                section("Chips") {
                    HStack {
                        LevelChip(level: "A1", theme: "Verbos")
                        LevelChip(level: "B2")
                        LevelChip(level: "C1", theme: "Cohesión")
                    }
                }

                section("Прогресс дня") {
                    DayProgressBar(completed: 3, total: 8)
                }

                section("Callouts") {
                    VStack(spacing: LoritoSpacing.sm) {
                        ForEach(CalloutKind.allCases, id: \.self) { kind in
                            CalloutBlock(kind, "Пример содержимого блока «\(kind.title)».")
                        }
                    }
                }

                section("Оценки SM-2") {
                    GradeButtons { _ in }
                }

                section("Карточка") {
                    StudyCardContainer {
                        LevelChip(level: "A1", theme: "Verbos")
                        Text("El verbo ser")
                            .font(LoritoFont.title)
                            .foregroundStyle(LoritoColor.textPrimary)
                        Text("быть — постоянное, сущность")
                            .font(LoritoFont.caption)
                            .foregroundStyle(LoritoColor.textSecondary)
                        CalloutBlock(.essence, "Ser выражает идентичность, происхождение и неизменные свойства.")
                        GradeButtons { _ in }
                    }
                }
            }
            .padding(LoritoSpacing.md)
        }
        .background(LoritoColor.surfaceSecondary.ignoresSafeArea())
        .navigationTitle("Компоненты")
        .preferredColorScheme(scheme.colorScheme)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(title.uppercased())
                .font(LoritoFont.label)
                .tracking(0.6)
                .foregroundStyle(LoritoColor.textSecondary)
            content()
        }
    }
}

#Preview("Light") {
    NavigationStack { ComponentGalleryView() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { ComponentGalleryView() }
        .preferredColorScheme(.dark)
}
