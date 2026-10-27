import Foundation
import Testing
@testable import Domain

private let today = Calendar.utcDay.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 9))!

private func mc(_ id: String, card: String = "A1-07") -> Exercise {
    Exercise(id: id, level: .a1, themeID: "a1-2", card: card, prompt: "Какой артикль? *___ idioma*",
             explanation: "", kind: .multipleChoice(options: ["el", "la"], answer: "el"))
}

private func fill(_ id: String) -> Exercise {
    Exercise(id: id, level: .a1, themeID: "a1-2", card: "A1-07", prompt: "?", explanation: "",
             kind: .fillInTheBlank(answer: "el", accept: []))
}

private func stats(streak: Int, today: Int) -> StudyStats {
    StudyStats(currentStreak: streak, bestStreak: streak, studiedToday: today, studiedThisWeek: today, studiedAllTime: today)
}

@Suite("Widget snapshot")
struct WidgetSnapshotTests {
    @Test("Spec scenario: streak 13, 8 due, 4 new, not studied today")
    func reflectsStats() {
        let s = WidgetSnapshot.make(stats: stats(streak: 13, today: 0), dueToday: 8, newToday: 4,
                                    trap: nil, trapNote: nil, exercises: [], today: today)
        #expect(s.version == WidgetSnapshot.currentVersion)
        #expect(s.currentStreak == 13)
        #expect(s.dueToday == 8 && s.newToday == 4 && s.remainingToday == 12)
        #expect(!s.studiedToday)
        #expect(s.wordOfDay == nil && s.questions.isEmpty)
        #expect(Calendar.utcDay.isDate(s.day, inSameDayAs: today))
    }

    @Test("Studied today once any grade is logged today")
    func studied() {
        let s = WidgetSnapshot.make(stats: stats(streak: 2, today: 3), dueToday: 0, newToday: 0,
                                    trap: nil, trapNote: nil, exercises: [], today: today)
        #expect(s.studiedToday)
    }

    @Test("At most three questions, multiple-choice only, deterministic per day")
    func questions() {
        let exercises = (1...6).map { mc(String(format: "A1-EX-%02d", $0)) } + [fill("A1-EX-50")]
        let a = WidgetSnapshot.make(stats: .empty, dueToday: 0, newToday: 0, trap: nil, trapNote: nil,
                                    exercises: exercises, today: today)
        let b = WidgetSnapshot.make(stats: .empty, dueToday: 0, newToday: 0, trap: nil, trapNote: nil,
                                    exercises: exercises.reversed(), today: today)
        #expect(a.questions.count == 3)
        #expect(a.questions.allSatisfy { $0.options == ["el", "la"] && $0.answer == "el" })
        #expect(!a.questions.contains { $0.id == "A1-EX-50" })
        #expect(a.questions == b.questions)
        #expect(Set(a.questions.map(\.id)).count == 3)
    }

    @Test("Fewer than three multiple-choice exercises → all of them")
    func fewQuestions() {
        let s = WidgetSnapshot.make(stats: .empty, dueToday: 0, newToday: 0, trap: nil, trapNote: nil,
                                    exercises: [mc("A1-EX-01")], today: today)
        #expect(s.questions.map(\.id) == ["A1-EX-01"])
    }

    @Test("Word of the day: first Spanish (emphasised) phrase of the trap, card title as note")
    func wordOfDay() {
        let trap = TrapCandidate(cardID: "A1-07", text: "**Род по переводу**: «проблема» женского рода, но ***el** problema* — мужского.")
        let s = WidgetSnapshot.make(stats: .empty, dueToday: 0, newToday: 0, trap: trap,
                                    trapNote: "Род существительных", exercises: [], today: today)
        #expect(s.wordOfDay == WidgetSnapshot.WordOfDay(spanish: "el problema", note: "Род существительных", cardID: "A1-07"))
    }

    @Test("No Spanish phrase in the trap → no word of the day")
    func noWord() {
        #expect(WidgetSnapshot.spanishPhrase(inMarkdown: "**Только русский**: текст.") == nil)
        #expect(WidgetSnapshot.spanishPhrase(inMarkdown: "Скажите *hola*, а потом *adiós*") == "hola")
    }

    @Test("Codable round-trip keeps version 1")
    func codable() throws {
        let trap = TrapCandidate(cardID: "A1-07", text: "*el agua*")
        let s = WidgetSnapshot.make(stats: stats(streak: 5, today: 1), dueToday: 1, newToday: 2, trap: trap,
                                    trapNote: "Род", exercises: [mc("A1-EX-01")], today: today)
        let data = try JSONEncoder().encode(s)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["version"] as? Int == 1)
        #expect(try JSONDecoder().decode(WidgetSnapshot.self, from: data) == s)
    }
}

@Suite("Session pace")
struct SessionPaceTests {
    @Test("Median seconds per card from this session; default 45 s; at least 1 minute while cards remain")
    func estimate() {
        #expect(SessionPace.minutesLeft(remaining: 14, secondsPerCard: []) == 11)            // 14 × 45 s = 10.5 → 11
        #expect(SessionPace.minutesLeft(remaining: 10, secondsPerCard: [30, 90, 60]) == 10)  // median 60 s
        #expect(SessionPace.minutesLeft(remaining: 1, secondsPerCard: [5]) == 1)
        #expect(SessionPace.minutesLeft(remaining: 0, secondsPerCard: [60]) == 0)
        #expect(SessionPace.minutesLeft(remaining: 4, secondsPerCard: [20, 40]) == 2)         // median 30 s
    }
}
