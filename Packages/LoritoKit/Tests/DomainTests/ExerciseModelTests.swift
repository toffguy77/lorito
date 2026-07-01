import Testing
import Foundation
@testable import Domain

@Suite("Exercise model decoding")
struct ExerciseModelTests {
    private func decode(_ json: String) throws -> Exercise {
        try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
    }

    @Test("Multiple-choice decodes with options and answer")
    func decodesMultipleChoice() throws {
        let ex = try decode(#"""
        {"id":"A1-EX-01","level":"A1","themeID":"a1-2","card":"A1-07",
         "type":"multiple-choice","prompt":"P","explanation":"E",
         "options":["el","la"],"answer":"la"}
        """#)
        #expect(ex.cardID == "A1-07")
        #expect(ex.level == .a1)
        guard case let .multipleChoice(options, answer) = ex.kind else {
            Issue.record("wrong kind"); return
        }
        #expect(options == ["el", "la"])
        #expect(answer == "la")
        #expect(ex.kind.isAutoChecked)
    }

    @Test("Fill-in-the-blank decodes with accept list defaulting to empty")
    func decodesFill() throws {
        let ex = try decode(#"""
        {"id":"A1-EX-06","level":"A1","themeID":"a1-2","card":"A1-08",
         "type":"fill-in-the-blank","prompt":"P","explanation":"E","answer":"casas"}
        """#)
        guard case let .fillInTheBlank(answer, accept) = ex.kind else {
            Issue.record("wrong kind"); return
        }
        #expect(answer == "casas")
        #expect(accept.isEmpty)
    }

    @Test("All six types decode")
    func decodesAllTypes() throws {
        let fragments = [
            #"{"id":"x","level":"A1","themeID":"a1-1","card":"A1-01","type":"matching","pairs":[{"left":"a","right":"1"},{"left":"b","right":"2"}]}"#,
            #"{"id":"x","level":"A1","themeID":"a1-1","card":"A1-01","type":"word-order","tokens":["yo","como"],"answer":"yo como"}"#,
            #"{"id":"x","level":"A1","themeID":"a1-1","card":"A1-01","type":"picture-matching","options":[{"image":"a.png","label":"a"},{"image":"b.png","label":"b"}]}"#,
            #"{"id":"x","level":"A1","themeID":"a1-1","card":"A1-01","type":"free-response","answer":"hola"}"#,
        ]
        for f in fragments { _ = try decode(f) }
        // free-response is self-assessed
        let fr = try decode(fragments[3])
        #expect(fr.kind.isAutoChecked == false)
    }

    @Test("Unknown type throws")
    func unknownTypeThrows() {
        #expect(throws: Exercise.DecodingError.unknownType("crossword")) {
            _ = try decode(#"{"id":"x","level":"A1","themeID":"a1-1","card":"A1-01","type":"crossword"}"#)
        }
    }

    @Test("Round-trips through encode/decode")
    func roundTrips() throws {
        let original = Exercise(
            id: "A1-EX-01", level: .a1, themeID: "a1-2", card: "A1-07",
            prompt: "P", explanation: "E",
            kind: .multipleChoice(options: ["el", "la"], answer: "la")
        )
        let data = try JSONEncoder().encode(original)
        let back = try JSONDecoder().decode(Exercise.self, from: data)
        #expect(back == original)
    }
}
