import Foundation
import Testing
import Domain
import Persistence
@testable import Features

@MainActor
private final class FakeRecognizer: SpeechRecognizing {
    var availability: RecognitionAvailability
    var level: Float = 0
    var results: [[String]] = []
    var recognizeCalls = 0
    var permissionRequests = 0
    init(_ availability: RecognitionAvailability) { self.availability = availability }
    func requestPermissions() async -> Bool { permissionRequests += 1; return false }
    func recognize(maxDuration: TimeInterval) async throws -> [String] {
        recognizeCalls += 1
        return results.isEmpty ? [] : results.removeFirst()
    }
    func stop() {}
}

private func ex(_ id: String, _ kind: ExerciseKind) -> Exercise {
    Exercise(id: id, level: .a1, themeID: "a1-1", card: "A1-01", prompt: "", explanation: "", kind: kind)
}
private let speak = ex("S", .speak(answer: "Buenos días", accept: []))

@Suite("Speaking and listening sessions")
@MainActor
struct ListeningFeatureTests {
    func store() throws -> SwiftDataUserDataStore {
        SwiftDataUserDataStore(container: try PersistenceController.makeContainer(config: .init(inMemory: true)), localMirror: nil)
    }
    func prefs() -> AudioExercisePreferences { AudioExercisePreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    @Test("Match → Хорошо applied to the card")
    func match() async throws {
        let s = try store()
        let r = FakeRecognizer(.available); r.results = [["buenos dias"]]
        let m = ExerciseSessionModel(store: s, exercises: [speak], recognizer: r, preferences: prefs())
        #expect(m.speakIsAuto)
        await m.recordSpeech()
        #expect(m.lastCheck?.isCorrect == true)
        #expect(try s.review(for: "A1-01")?.lastGrade == Grade.good.rawValue)
    }

    @Test("Two failed attempts → attempt recorded with transcript, review unchanged, reference revealed")
    func twoMisses() async throws {
        let s = try store()
        let r = FakeRecognizer(.available); r.results = [["buenas noches"], ["bueno"]]
        let m = ExerciseSessionModel(store: s, exercises: [speak], recognizer: r, preferences: prefs())
        await m.recordSpeech()
        #expect(!m.isRevealed && m.speakAttempts == 1)
        await m.recordSpeech()
        #expect(m.isRevealed)
        #expect(try s.review(for: "A1-01") == nil)
        #expect(try s.allAttempts().map(\.transcript) == ["bueno"])
        // Self-assessed Опять afterwards → another attempt only, never a lapse.
        m.selfGrade(.again)
        #expect(try s.review(for: "A1-01") == nil && s.allAttempts().count == 2)
    }

    @Test("Unsupported or denied → self-assessed; no recognition request when unsupported")
    func selfAssessed() async throws {
        for availability in [RecognitionAvailability.unsupported, .denied] {
            let s = try store()
            let r = FakeRecognizer(availability)
            let m = ExerciseSessionModel(store: s, exercises: [speak], recognizer: r, preferences: prefs())
            #expect(!m.speakIsAuto && m.canSubmit)
            await m.recordSpeech()
            #expect(r.recognizeCalls == 0)
            m.submit()
            #expect(m.isRevealed)
            m.selfGrade(.hard)
            #expect(try s.review(for: "A1-01")?.lastGrade == Grade.hard.rawValue)
        }
    }

    @Test("No Spanish voice → listen-choose and dictation excluded; skip removes the rest of the session's listening")
    func voiceAndSkip() throws {
        let s = try store()
        let list = [ex("L", .listenChoose(audio: "Hola", options: ["a", "b"], answer: "a")),
                    ex("D", .dictation(audio: "Hola", accept: [])), speak,
                    ex("M", .multipleChoice(options: ["a", "b"], answer: "a")), ex("D2", .dictation(audio: "Adiós", accept: []))]
        #expect(ExerciseSessionModel(store: s, exercises: list, hasSpanishVoice: false, preferences: prefs()).count == 2)
        let p = prefs()
        let m = ExerciseSessionModel(store: s, exercises: list, preferences: p)
        #expect(m.count == 5 && m.isListenChoose)
        m.skipListening()
        #expect(m.count == 2 && m.isSpeak)
        #expect(try s.allAttempts().isEmpty)
        // A new session within 15 minutes has no listening either.
        #expect(ExerciseSessionModel(store: s, exercises: list, preferences: p).count == 2)
    }

    @Test("Settings toggle: speaking off → no speak exercise selected")
    func toggle() throws {
        let p = prefs()
        p.speakingEnabled = false
        let m = ExerciseSessionModel(store: try store(), exercises: [speak, ex("M", .multipleChoice(options: ["a", "b"], answer: "a"))],
                                     preferences: p)
        #expect(m.count == 1 && !m.isSpeak)
    }

    @Test("Dictation: accent-only miss is «почти» and graded Трудно")
    func dictation() throws {
        let s = try store()
        let m = ExerciseSessionModel(store: s, exercises: [ex("D", .dictation(audio: "¿Cómo estás?", accept: []))], preferences: prefs())
        m.typedText = "como estas"
        m.submit()
        #expect(m.lastCheck?.isAlmost == true && m.lastCheck?.grade == .hard)
        #expect(try s.review(for: "A1-01")?.lastGrade == Grade.hard.rawValue)
    }
}
