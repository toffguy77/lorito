import Testing
@testable import DesignSystem

@Suite("Grade buttons")
struct GradeButtonsTests {
    @Test("Without captions each button shows its label only")
    func noCaptions() {
        let items = GradeButtons.items(captions: [:])
        #expect(items.map(\.title) == ["Опять", "Трудно", "Хорошо", "Легко"])
        #expect(items.allSatisfy { $0.caption == nil })
        #expect(items.map(\.accessibilityLabel) == ["Опять", "Трудно", "Хорошо", "Легко"])
    }

    @Test("Captions render on a second line beneath the label")
    func withCaptions() {
        let items = GradeButtons.items(captions: [.again: "сегодня", .hard: "1 день", .good: "3 дня", .easy: "8 дней"])
        #expect(items.map(\.caption) == ["сегодня", "1 день", "3 дня", "8 дней"])
        #expect(items[2].accessibilityLabel == "Хорошо, 3 дня")
    }

    @Test("Empty caption strings are dropped")
    func emptyCaption() {
        let items = GradeButtons.items(captions: [.good: ""])
        #expect(items[2].caption == nil)
    }

    @Test("Adjacent grade backgrounds differ in lightness in both themes")
    func lightnessSeparation() throws {
        let values = try StudyGrade.allCases.map { try #require(LoritoColor.palette[$0.backgroundToken]) }
        for i in 1..<values.count {
            for pick in [\LoritoColorValue.light, \LoritoColorValue.dark] {
                let a = Contrast.luminance(values[i - 1][keyPath: pick])
                let b = Contrast.luminance(values[i][keyPath: pick])
                let ratio = (max(a, b) + 0.05) / (min(a, b) + 0.05)
                #expect(ratio >= 1.3, "\(StudyGrade.allCases[i - 1]) vs \(StudyGrade.allCases[i]): \(ratio)")
            }
        }
    }

    @Test("Grade labels are readable on their backgrounds")
    func labelContrast() {
        let p = LoritoColor.palette
        let pairs = [("dangerText", "dangerSoft"), ("onInk", "inkTrack"), ("onAccent", "accent"), ("onHighlight", "highlight")]
        for (fg, bg) in pairs {
            #expect(Contrast.ratio(p[fg]!.light, p[bg]!.light) >= 4.5, "\(fg)/\(bg) light")
            #expect(Contrast.ratio(p[fg]!.dark, p[bg]!.dark) >= 4.5, "\(fg)/\(bg) dark")
        }
    }
}
