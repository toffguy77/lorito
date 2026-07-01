import Testing
import Foundation
@testable import Domain

private func ex(_ kind: ExerciseKind, card: String = "A1-07") -> Exercise {
    Exercise(id: "EX", level: .a1, themeID: "a1-2", card: card,
             prompt: "P", explanation: "E", kind: kind)
}

@Suite("Exercise checker")
struct ExerciseCheckerTests {
    // MARK: multiple-choice

    @Test("Correct option is correct and grades good")
    func mcCorrect() throws {
        let r = try ExerciseChecker.check(ex(.multipleChoice(options: ["el", "la"], answer: "la")),
                                          answer: .option("la"))
        #expect(r.isCorrect)
        #expect(r.grade == .good)
        #expect(r.correctAnswer == "la")
    }

    @Test("Wrong option is incorrect and grades again")
    func mcWrong() throws {
        let r = try ExerciseChecker.check(ex(.multipleChoice(options: ["el", "la"], answer: "la")),
                                          answer: .option("el"))
        #expect(r.isCorrect == false)
        #expect(r.grade == .again)
    }

    // MARK: fill-in-the-blank

    @Test("Exact typed answer is correct")
    func fillExact() throws {
        let r = try ExerciseChecker.check(ex(.fillInTheBlank(answer: "casas", accept: [])),
                                          answer: .text("casas"))
        #expect(r.isCorrect)
        #expect(r.grade == .good)
    }

    @Test("Case, diacritics and surrounding whitespace are ignored")
    func fillNormalized() throws {
        let e = ex(.fillInTheBlank(answer: "lápices", accept: []))
        #expect(try ExerciseChecker.check(e, answer: .text("  LAPICES ")).isCorrect)
        #expect(try ExerciseChecker.check(e, answer: .text("lapices")).isCorrect)
    }

    @Test("Accepted alternative is correct")
    func fillAccept() throws {
        let r = try ExerciseChecker.check(ex(.fillInTheBlank(answer: "la", accept: ["LA"])),
                                          answer: .text("la"))
        #expect(r.isCorrect)
    }

    @Test("Non-matching answer is incorrect and grades again")
    func fillWrong() throws {
        let r = try ExerciseChecker.check(ex(.fillInTheBlank(answer: "casas", accept: [])),
                                          answer: .text("casa"))
        #expect(r.isCorrect == false)
        #expect(r.grade == .again)
    }

    // MARK: grade mapping override + mismatches

    @Test("Passing grade is configurable")
    func passingGradeOverride() throws {
        let r = try ExerciseChecker.check(ex(.multipleChoice(options: ["el", "la"], answer: "la")),
                                          answer: .option("la"), passingGrade: .easy)
        #expect(r.grade == .easy)
    }

    @Test("Answer kind mismatch throws")
    func mismatchThrows() {
        #expect(throws: ExerciseChecker.CheckError.answerMismatch) {
            _ = try ExerciseChecker.check(ex(.multipleChoice(options: ["el", "la"], answer: "la")),
                                          answer: .text("la"))
        }
    }

    @Test("Free-response is not auto-checkable")
    func freeResponseThrows() {
        #expect(throws: ExerciseChecker.CheckError.notAutoCheckable) {
            _ = try ExerciseChecker.check(ex(.freeResponse(answer: "hola", accept: [])),
                                          answer: .text("hola"))
        }
    }

    @Test("Normalization folds case and diacritics")
    func normalize() {
        #expect(ExerciseChecker.normalize("  Está ") == ExerciseChecker.normalize("esta"))
        #expect(ExerciseChecker.normalize("Niño") == ExerciseChecker.normalize("nino"))
    }
}
