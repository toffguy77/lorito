import Foundation
import Testing
import Domain
@testable import Features

@Suite("Speech service")
@MainActor
struct SpeechServiceTests {
    @Test("Non-speakable text is never spoken")
    func nonSpeakable() {
        let service = SystemSpeechService(settings: { .default }, defaults: UserDefaults(suiteName: "t.\(UUID())")!)
        service.speak("1492", context: .content)
        service.speak("проблема", context: .content)
        #expect(service.speakingText == nil)
        #expect(!service.showsSilenceHint)
    }

    @Test("Silence hint shows once per device on the first content speech", .enabled(if: SystemSpeechService.voice(for: .spain) != nil))
    func hintOnce() {
        let defaults = UserDefaults(suiteName: "t.\(UUID())")!
        let service = SystemSpeechService(settings: { .default }, defaults: defaults)
        service.speak("el agua", context: .content)
        #expect(service.showsSilenceHint)
        service.showsSilenceHint = false
        service.stop()
        service.speak("la mano", context: .content)
        #expect(!service.showsSilenceHint)
        let second = SystemSpeechService(settings: { .default }, defaults: defaults)
        second.speak("hola", context: .content)
        #expect(!second.showsSilenceHint)
        second.stop()
    }

    @Test("Speaking the same text again stops it; another text replaces it", .enabled(if: SystemSpeechService.voice(for: .spain) != nil))
    func toggle() {
        let service = SystemSpeechService(settings: { .default }, defaults: UserDefaults(suiteName: "t.\(UUID())")!)
        service.speak("*el agua*", context: .content)
        #expect(service.speakingText == "el agua")
        service.speak("la mano", context: .content)
        #expect(service.speakingText == "la mano")
        service.speak("la mano", context: .content)
        #expect(service.speakingText == nil)
    }
}

private final class SettingsStore: UserDataStore {
    var settings = UserSettings.default
    func loadSettings() throws -> UserSettings { settings }
    func saveSettings(_ s: UserSettings) throws { settings = s }
    func allReviews() throws -> [ReviewState] { [] }
    func review(for cardID: String) throws -> ReviewState? { nil }
    func upsertReview(_ review: ReviewState) throws {}
    func appendEvent(_ event: StudyEvent) throws {}
    func allEvents() throws -> [StudyEvent] { [] }
}

@Suite("Audio settings")
@MainActor
struct AudioSettingsModelTests {
    @Test("Changes persist and keep other settings intact")
    func persist() {
        let store = SettingsStore()
        store.settings.targetLevel = .b1
        let model = AudioSettingsModel(store: store)
        model.variant = .latinAmerica
        model.rate = .slow
        model.playWhenSilent = true
        #expect(store.settings.spanishVariant == .latinAmerica)
        #expect(store.settings.speechRate == .slow)
        #expect(store.settings.playAudioWhenSilent)
        #expect(store.settings.targetLevel == .b1)
    }
}
