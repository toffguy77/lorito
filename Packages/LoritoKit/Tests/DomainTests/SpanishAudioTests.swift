import Testing
@testable import Domain

@Suite("Speakable text")
struct SpeakableTextTests {
    @Test("Extract strips Markdown markers and keeps ¿ ¡")
    func extract() {
        #expect(SpeakableText.extract("*¿Cómo te **llamas**?*") == "¿Cómo te llamas?")
        #expect(SpeakableText.extract("**¡Hola!** `code` _ya_") == "¡Hola! code ya")
        #expect(SpeakableText.extract("[*el agua*](lorito-es://span?text=x)") == "el agua")
    }

    @Test("Speakable needs a Latin letter")
    func speakable() {
        for s in ["el agua", "ñ", "Ñandú", "¿qué?", "über"] { #expect(SpeakableText.isSpeakable(s), "\(s)") }
        for s in ["1492", "«…»", "—", "проблема", "", "  ", "1.000,50"] { #expect(!SpeakableText.isSpeakable(s), "\(s)") }
    }

    @Test("Spans of a Markdown block: speakable emphasis only, in order")
    func spans() {
        #expect(SpeakableText.spans(inMarkdown: "*el agua* и *1492*, *¿qué tal?* и снова *el agua*") == ["el agua", "¿qué tal?"])
    }
}

@Suite("Audio session policy")
struct AudioSessionPolicyTests {
    @Test("Content respects silent mode unless the setting is on; listening always plays")
    func mapping() {
        #expect(AudioSessionPolicy.category(for: .content, playWhenSilent: false) == .ambient)
        #expect(AudioSessionPolicy.category(for: .content, playWhenSilent: true) == .playbackDuckingOthers)
        #expect(AudioSessionPolicy.category(for: .listeningExercise, playWhenSilent: false) == .playback)
        #expect(AudioSessionPolicy.category(for: .listeningExercise, playWhenSilent: true) == .playback)
    }
}

@Suite("Spanish variant and speed")
struct SpanishVariantTests {
    @Test("Variant maps to a locale and a Russian title; Spain is the default")
    func variant() {
        #expect(SpanishVariant.spain.localeIdentifier == "es-ES")
        #expect(SpanishVariant.latinAmerica.localeIdentifier == "es-MX")
        #expect(SpanishVariant.spain.title == "Испания")
        #expect(SpanishVariant.latinAmerica.title == "Латинская Америка")
        #expect(UserSettings.default.spanishVariant == .spain)
        #expect(UserSettings.default.speechRate == .normal)
        #expect(UserSettings.default.playAudioWhenSilent == false)
    }

    @Test("Slow is ~0.8 × normal")
    func rate() {
        #expect(abs(SpeechRate.slow.multiplier - 0.8) < 0.001)
        #expect(SpeechRate.normal.multiplier == 1)
        #expect(SpeechRate.slow.title == "Медленно")
    }
}
