import Testing
import Foundation
@testable import Domain

private func decode(_ json: String) throws -> Exercise {
    try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
}
private let base = #""id":"A1-EX-90","level":"A1","themeID":"a1-1","card":"A1-01","prompt":"?","explanation":"""#

@Suite("Listening exercise kinds")
struct ListeningKindTests {
    @Test("Three new types decode; listen-choose and dictation auto-checked; speak depends on recognition")
    func decodeTypes() throws {
        let lc = try decode("{\(base),\"type\":\"listen-choose\",\"audio\":\"¿Dónde está?\",\"options\":[\"где\",\"когда\"],\"answer\":\"где\"}")
        #expect(lc.kind == .listenChoose(audio: "¿Dónde está?", options: ["где", "когда"], answer: "где"))
        let d = try decode("{\(base),\"type\":\"dictation\",\"audio\":\"Me llamo Ana.\",\"accept\":[\"me llamo ana\"]}")
        #expect(d.kind == .dictation(audio: "Me llamo Ana.", accept: ["me llamo ana"]))
        let s = try decode("{\(base),\"type\":\"speak\",\"answer\":\"Buenos días\"}")
        #expect(s.kind == .speak(answer: "Buenos días", accept: []))
        #expect(lc.kind.isAutoChecked && d.kind.isAutoChecked)
        #expect(s.kind.isAutoChecked(speechRecognitionAvailable: true))
        #expect(!s.kind.isAutoChecked(speechRecognitionAvailable: false))
        #expect(!s.kind.isAutoChecked)
        // Round trip.
        let again = try JSONDecoder().decode(Exercise.self, from: JSONEncoder().encode(d))
        #expect(again == d)
    }
}

@Suite("Dictation checking")
struct DictationCheckTests {
    let ex = Exercise(id: "X", level: .a1, themeID: "a1-1", card: "A1-01", prompt: "", explanation: "",
                      kind: .dictation(audio: "¿Cómo te llamas, Ana?", accept: []))

    func check(_ typed: String) throws -> ExerciseCheck { try ExerciseChecker.check(ex, answer: .text(typed)) }

    @Test("Case, whitespace and punctuation (incl. ¿ ¡) are ignored")
    func normalisation() throws {
        let r = try check("  como TE   llamas ana ")
        #expect(r.isAlmost)                                   // accent missing on "cómo"
        let exact = try check("Cómo te llamas Ana")
        #expect(exact.isCorrect && exact.grade == .good && !exact.isAlmost)
    }

    @Test("Accent-only difference → почти / Трудно with the differing words")
    func almost() throws {
        let r = try check("¿Como te llamas, Ana?")
        #expect(r.isAlmost && r.grade == .hard && !r.isCorrect)
        #expect(r.wordDiff == [.init(expected: "cómo", typed: "como")])
    }

    @Test("Wrong → Опять with a word-level diff")
    func wrong() throws {
        let r = try check("como se llama Ana")
        #expect(!r.isCorrect && !r.isAlmost && r.grade == .again)
        #expect(r.wordDiff?.contains(.init(expected: "te", typed: "se")) == true)
        #expect(r.correctAnswer == "¿Cómo te llamas, Ana?")
    }

    @Test("Listen-choose checks the chosen option")
    func listenChoose() throws {
        let lc = Exercise(id: "Y", level: .a1, themeID: "a1-1", card: "A1-01", prompt: "", explanation: "",
                          kind: .listenChoose(audio: "Hola", options: ["привет", "пока"], answer: "привет"))
        #expect(try ExerciseChecker.check(lc, answer: .option("привет")).isCorrect)
        #expect(try ExerciseChecker.check(lc, answer: .option("пока")).grade == .again)
    }
}

@Suite("Speech transcript comparison")
struct TranscriptTests {
    let ex = Exercise(id: "Z", level: .a1, themeID: "a1-1", card: "A1-01", prompt: "", explanation: "",
                      kind: .speak(answer: "Buenos días", accept: ["buen día"]))

    @Test("Best transcript or any alternative matches answer/accept, diacritics ignored")
    func matching() throws {
        #expect(try ExerciseChecker.check(ex, answer: .transcripts(["buenos dias"])).isCorrect)
        #expect(try ExerciseChecker.check(ex, answer: .transcripts(["bueno día", "Buen día."])).isCorrect)
        let miss = try ExerciseChecker.check(ex, answer: .transcripts(["buenas noches"]))
        #expect(!miss.isCorrect && !miss.isAlmost)
    }
}

@Suite("Audio exercise policy")
struct AudioExercisePolicyTests {
    func ex(_ kind: ExerciseKind) -> Exercise {
        Exercise(id: kind.typeName, level: .a1, themeID: "a1-1", card: "A1-01", prompt: "", explanation: "", kind: kind)
    }
    var all: [Exercise] {
        [ex(.multipleChoice(options: ["a", "b"], answer: "a")), ex(.listenChoose(audio: "x", options: ["a", "b"], answer: "a")),
         ex(.dictation(audio: "x", accept: [])), ex(.speak(answer: "x", accept: []))]
    }
    let now = Date()

    @Test("Turned off / skipped for 15 minutes / no Spanish voice")
    func filter() {
        #expect(AudioExercisePolicy().filter(all, now: now).count == 4)
        #expect(AudioExercisePolicy(speakingEnabled: false).filter(all, now: now).map(\.id)
                == ["multiple-choice", "listen-choose", "dictation"])
        let skip = AudioExercisePolicy(listeningSkippedUntil: now.addingTimeInterval(AudioExercisePolicy.skipDuration))
        #expect(skip.filter(all, now: now).map(\.id) == ["multiple-choice", "speak"])
        #expect(skip.filter(all, now: now.addingTimeInterval(16 * 60)).count == 4)
        #expect(AudioExercisePolicy(hasSpanishVoice: false).filter(all, now: now).map(\.id) == ["multiple-choice", "speak"])
    }
}
