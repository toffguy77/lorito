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

    var foreground: Color {
        switch self {
        case .again: return LoritoColor.danger
        case .hard: return LoritoColor.warning
        case .good: return LoritoColor.success
        case .easy: return LoritoColor.onAccent
        }
    }

    var background: Color {
        switch self {
        case .again: return LoritoColor.dangerSoft
        case .hard: return LoritoColor.warningSoft
        case .good: return LoritoColor.successSoft
        case .easy: return LoritoColor.accent
        }
    }
}

/// A row of the four SM-2 grade buttons.
public struct GradeButtons: View {
    private let onGrade: (StudyGrade) -> Void

    public init(onGrade: @escaping (StudyGrade) -> Void) {
        self.onGrade = onGrade
    }

    public var body: some View {
        HStack(spacing: LoritoSpacing.xs) {
            ForEach(StudyGrade.allCases, id: \.self) { grade in
                Button {
                    onGrade(grade)
                } label: {
                    Text(grade.title)
                        .font(LoritoFont.body.weight(.semibold))
                        .foregroundStyle(grade.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LoritoSpacing.sm)
                        .background(grade.background, in: RoundedRectangle(cornerRadius: LoritoRadius.md))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(grade.title)
            }
        }
    }
}

#Preview {
    GradeButtons { _ in }
        .padding()
        .background(LoritoColor.surface)
}
