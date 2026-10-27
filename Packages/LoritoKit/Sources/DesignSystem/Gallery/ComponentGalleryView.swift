import Domain
import SwiftUI

/// Developer-facing gallery that renders every design-system component in the
/// chosen appearance, plus focus-mode (ink) samples.
public struct ComponentGalleryView: View {
    @State private var scheme: SchemeChoice = .system
    @State private var tab = 0

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

                section("Типографика") {
                    VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
                        Text("¡Hola!").loritoStyle(.display)
                        Text("Заголовок").loritoStyle(.title)
                        Text("12").loritoStyle(.number)
                        Text("Раздел").loritoStyle(.heading)
                        Text("Текст интерфейса на русском.").loritoStyle(.body)
                        Text("Акцент в тексте").loritoStyle(.bodyStrong)
                        Text("Подпись").loritoStyle(.caption)
                        Text("Метка").loritoStyle(.label)
                        SpanishText("el problema, la mano")
                        SpanishText("el agua fría", size: .inline)
                    }
                    .foregroundStyle(LoritoColor.textPrimary)
                }

                section("Звук") {
                    HStack(spacing: LoritoSpacing.sm) {
                        SpeakButton(isSpeaking: false) {}
                        SpeakButton(isSpeaking: true) {}
                        SpeakButton(isSpeaking: false, tone: .ink) {}
                            .padding(6)
                            .background(LoritoColor.ink, in: RoundedRectangle(cornerRadius: LoritoRadius.sm))
                    }
                }

                section("Chips") {
                    HStack {
                        LevelChip(level: "A1", theme: "Тема 2")
                        LevelChip("Повтор", tone: .neutral)
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

                section("Кнопки") {
                    VStack(spacing: LoritoSpacing.sm) {
                        PrimaryButton("Начать", variant: .ink) {}
                        PrimaryButton("Ещё раз", variant: .outline) {}
                        PrimaryButton("Недоступно", variant: .ink) {}.disabled(true)
                    }
                }

                section("План дня") {
                    PlanHeroCard(
                        total: 12,
                        caption: "карточек в плане дня",
                        parts: [
                            .init(count: 8, label: "повторить", tone: .highlight),
                            .init(count: 4, label: "новых", tone: .accent),
                        ]
                    ) {
                        PrimaryButton("Начать", variant: .highlight) {}
                    }
                }

                section("Тело карточки (Markdown)") {
                    CardBodyView(
                        """
                        *Ser* выражает идентичность и неизменные свойства.

                        ## Спряжение (presente)
                        | Лицо | Форма |
                        |------|-------|
                        | yo | *soy* |
                        | tú | *eres* |
                        """
                    )
                }

                section("Режим фокуса") {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        SessionProgressBar(segments: [.passed, .passed, .missed, .current, .pending, .pending, .pending])
                        StudyCardContainer {
                            LevelChip(level: "A1", theme: "Тема 2")
                            Text("Род существительных")
                                .font(LoritoFont.body)
                                .foregroundStyle(LoritoColor.textSecondary)
                            Text("¿el или la?")
                                .loritoStyle(.title)
                                .foregroundStyle(LoritoColor.textPrimary)
                            CalloutBlock(.essence, "Два рода, среднего нет.")
                        }
                        GradeButtons { _ in }
                        GradeButtons(captions: [.again: "сегодня", .hard: "1 день", .good: "3 дня", .easy: "8 дней"]) { _ in }
                        PrimaryButton("Показать ответ", variant: .highlight) {}
                    }
                    .padding(LoritoSpacing.md)
                    .background(LoritoColor.ink, in: RoundedRectangle(cornerRadius: LoritoRadius.lg))
                }

                section("iPad: навигация") {
                    VStack(alignment: .leading, spacing: LoritoSpacing.md) {
                        TopTabBar(items: [
                            FloatingTabItem(id: 0, title: "Сегодня", systemImage: "sun.max"),
                            FloatingTabItem(id: 1, title: "Каталог", systemImage: "point.topleft.down.to.point.bottomright.curvepath"),
                        ], selection: $tab)
                        Sidebar(items: [
                            FloatingTabItem(id: 0, title: "Сегодня", systemImage: "sun.max"),
                            FloatingTabItem(id: 1, title: "Каталог", systemImage: "point.topleft.down.to.point.bottomright.curvepath"),
                        ], selection: $tab, path: [
                            LevelPathProgress(level: "A1", fraction: 0.7),
                            LevelPathProgress(level: "A2", fraction: 0.25),
                        ])
                        .frame(width: LoritoLayout.sidebarWidth, height: 320)
                    }
                }

                section("iPad: клавиатура") {
                    VStack(alignment: .leading, spacing: LoritoSpacing.sm) {
                        HStack { KeyCap("1", tone: .surface); KeyCap("Пробел", tone: .surface); KeyCap("esc", tone: .surface) }
                        KeyboardHintsPanel(hints: [.init("Показать ответ", key: "Пробел"), .init("Оценка", key: "1 – 4")])
                        GradeButtons(captions: [.again: "сегодня", .hard: "1 день", .good: "3 дня", .easy: "8 дней"],
                                     showsKeyCaps: true) { _ in }
                    }
                    .padding(LoritoSpacing.md)
                    .background(LoritoColor.ink, in: RoundedRectangle(cornerRadius: LoritoRadius.lg))
                }

                section("Таб-бар") {
                    FloatingTabBar(items: [
                        FloatingTabItem(id: 0, title: "Сегодня", systemImage: "sun.max"),
                        FloatingTabItem(id: 1, title: "Каталог", systemImage: "point.topleft.down.to.point.bottomright.curvepath"),
                        FloatingTabItem(id: 2, title: "Прогресс", systemImage: "flame"),
                        FloatingTabItem(id: 3, title: "Настройки", systemImage: "slider.horizontal.3"),
                    ], selection: $tab)
                }
            }
            .padding(LoritoSpacing.screenGutter)
        }
        .background(LoritoColor.surface.ignoresSafeArea())
        .navigationTitle("Компоненты")
        .preferredColorScheme(scheme.colorScheme)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LoritoSpacing.xs) {
            Text(title)
                .loritoStyle(.label)
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
