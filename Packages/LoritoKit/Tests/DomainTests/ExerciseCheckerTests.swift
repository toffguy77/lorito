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

    // MARK: matching

    private func matchingEx() -> Exercise {
        ex(.matching(pairs: [MatchPair(left: "uno", right: "1"), MatchPair(left: "dos", right: "2")]))
    }

    @Test("All matching pairs correct is correct")
    func matchingAllCorrect() throws {
        let r = try ExerciseChecker.check(matchingEx(), answer: .matches(["uno": "1", "dos": "2"]))
        #expect(r.isCorrect)
        #expect(r.grade == .good)
    }

    @Test("Any wrong matching pair is incorrect")
    func matchingOneWrong() throws {
        let r = try ExerciseChecker.check(matchingEx(), answer: .matches(["uno": "2", "dos": "1"]))
        #expect(r.isCorrect == false)
        #expect(r.grade == .again)
    }

    @Test("Matching pairing is order-independent")
    func matchingOrderIndependent() throws {
        // Same map, different insertion order — still correct.
        let r = try ExerciseChecker.check(matchingEx(), answer: .matches(["dos": "2", "uno": "1"]))
        #expect(r.isCorrect)
    }

    // MARK: word-order

    private func wordOrderEx() -> Exercise {
        ex(.wordOrder(tokens: ["yo", "como", "pan"], answer: "Yo como pan", accept: []))
    }

    @Test("Correct word order is correct (normalized)")
    func wordOrderCorrect() throws {
        let r = try ExerciseChecker.check(wordOrderEx(), answer: .ordering(["yo", "como", "pan"]))
        #expect(r.isCorrect)
        #expect(r.correctAnswer == "Yo como pan")
    }

    @Test("Wrong word order is incorrect")
    func wordOrderWrong() throws {
        let r = try ExerciseChecker.check(wordOrderEx(), answer: .ordering(["como", "yo", "pan"]))
        #expect(r.isCorrect == false)
    }

    @Test("Accepted alternative ordering is correct")
    func wordOrderAccept() throws {
        let e = ex(.wordOrder(tokens: ["no", "lo", "sé"], answer: "No lo sé", accept: ["Yo no lo sé"]))
        #expect(try ExerciseChecker.check(e, answer: .ordering(["no", "lo", "sé"])).isCorrect)
    }

    // MARK: picture-matching

    private func pictureEx() -> Exercise {
        ex(.pictureMatching(options: [PictureOption(image: "casa.png", label: "casa"),
                                      PictureOption(image: "perro.png", label: "perro")]))
    }

    @Test("All labels matched to their images is correct")
    func pictureAllCorrect() throws {
        let r = try ExerciseChecker.check(pictureEx(),
                                          answer: .matches(["casa": "casa.png", "perro": "perro.png"]))
        #expect(r.isCorrect)
    }

    @Test("A mismatched label is incorrect")
    func pictureWrong() throws {
        let r = try ExerciseChecker.check(pictureEx(),
                                          answer: .matches(["casa": "perro.png", "perro": "casa.png"]))
        #expect(r.isCorrect == false)
    }

    // MARK: answer-kind mismatches for the new types

    @Test("Matching requires a matches answer")
    func matchingMismatch() {
        #expect(throws: ExerciseChecker.CheckError.answerMismatch) {
            _ = try ExerciseChecker.check(matchingEx(), answer: .text("uno"))
        }
    }

    @Test("Word-order requires an ordering answer")
    func wordOrderMismatch() {
        #expect(throws: ExerciseChecker.CheckError.answerMismatch) {
            _ = try ExerciseChecker.check(wordOrderEx(), answer: .option("yo"))
        }
    }
}
