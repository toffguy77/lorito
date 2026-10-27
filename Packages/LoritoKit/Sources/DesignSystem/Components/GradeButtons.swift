import SwiftUI

/// The four SM-2 self-grades.
public enum StudyGrade: String, CaseIterable, Sendable {
    case again   // Опять
    case hard    // Трудно
    case good    // Хорошо
    case easy    // Легко

    public var title: String {
        switch self {
        case .again: return "Опять"
        case .hard: return "Трудно"
        case .good: return "Хорошо"
        case .easy: return "Легко"
        }
    }

    /// Token names, so tests can check lightness separation on raw values.
    /// Трудно uses `inkTrack` (not `inkRaised`) so it stays lighter than the
    /// dark-theme Опять background.
    var backgroundToken: String {
        switch self {
        case .again: return "dangerSoft"
        case .hard: return "inkTrack"
        case .good: return "accent"
        case .easy: return "highlight"
        }
    }

    var foreground: Color {
        switch self {
        case .again: return LoritoColor.dangerText
        case .hard: return LoritoColor.onInk
        case .good: return LoritoColor.onAccent
        case .easy: return LoritoColor.onHighlight
        }
    }

    /// Hardware-keyboard key: 1 Опять … 4 Легко.
    public var key: String {
        switch self {
        case .again: return "1"
        case .hard: return "2"
        case .good: return "3"
        case .easy: return "4"
        }
    }

    var captionColor: Color {
        self == .hard ? LoritoColor.onInkSecondary : foreground
    }

    var background: Color {
        switch self {
        case .again: return LoritoColor.dangerSoft
        case .hard: return LoritoColor.inkTrack
        case .good: return LoritoColor.accent
        case .easy: return LoritoColor.highlight
        }
    }
}

/// What one grade button shows: the label and an optional second line.
public struct GradeButtonItem: Equatable, Sendable {
    public let grade: StudyGrade
    public let title: String
    public let caption: String?
    /// What VoiceOver reads for the caption (defaults to the caption).
    public let spokenCaption: String?

    /// VoiceOver label: "Хорошо, через 3 дня" with a caption, the title alone without.
    public var accessibilityLabel: String {
        (spokenCaption ?? caption).map { "\(title), \($0)" } ?? title
    }
}

/// A row of the four SM-2 grade buttons, each with an optional caption line
/// (e.g. the interval preview supplied by the study flow).
public struct GradeButtons: View {
    private let items: [GradeButtonItem]
    private let showsKeyCaps: Bool
    private let onGrade: (StudyGrade) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        captions: [StudyGrade: String] = [:],
        spokenCaptions: [StudyGrade: String] = [:],
        showsKeyCaps: Bool = false,
        onGrade: @escaping (StudyGrade) -> Void
    ) {
        self.items = Self.items(captions: captions, spokenCaptions: spokenCaptions)
        self.showsKeyCaps = showsKeyCaps
        self.onGrade = onGrade
    }

    /// Pure layout model: four items in grade order; empty captions are dropped.
    nonisolated public static func items(
        captions: [StudyGrade: String],
        spokenCaptions: [StudyGrade: String] = [:]
    ) -> [GradeButtonItem] {
        StudyGrade.allCases.map { grade in
            let caption = captions[grade].flatMap { $0.isEmpty ? nil : $0 }
            let spoken = caption == nil ? nil : spokenCaptions[grade].flatMap { $0.isEmpty ? nil : $0 }
            return GradeButtonItem(grade: grade, title: grade.title, caption: caption, spokenCaption: spoken)
        }
    }

    public var body: some View {
        // Four across truncates at accessibility sizes; fall back to 2×2.
        let columns = dynamicTypeSize.isAccessibilitySize && !showsKeyCaps ? 2 : 4
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LoritoSpacing.xs), count: columns),
                  spacing: LoritoSpacing.xs) {
            ForEach(items, id: \.grade) { item in
                Button {
                    onGrade(item.grade)
                } label: {
                    HStack(spacing: LoritoSpacing.xs) {
                        VStack(spacing: 3) {
                            Text(item.title)
                                .font(LoritoFont.bodyStrong)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if let caption = item.caption {
                                Text(caption)
                                    .font(LoritoFont.caption)
                                    .foregroundStyle(item.grade.captionColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        if showsKeyCaps {
                            KeyCap(item.grade.key, tone: .surface)
                        }
                    }
                    .foregroundStyle(item.grade.foreground)
                    .frame(maxWidth: .infinity, minHeight: LoritoLayout.primaryButtonHeight)
                    .padding(.horizontal, LoritoSpacing.xxs)
                    .background(item.grade.background, in: RoundedRectangle(cornerRadius: LoritoRadius.md + 2, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(Character(item.grade.key)), modifiers: [])
                .loritoHover()
                .accessibilityLabel(item.accessibilityLabel)
            }
        }
    }
}

#Preview {
    VStack(spacing: LoritoSpacing.md) {
        GradeButtons { _ in }
        GradeButtons(captions: [.again: "сегодня", .hard: "1 день", .good: "3 дня", .easy: "8 дней"]) { _ in }
    }
    .padding()
    .background(LoritoColor.ink)
}
