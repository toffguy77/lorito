import SwiftUI
import Domain
import DesignSystem

extension EnvironmentValues {
    /// The speech service when a Spanish voice exists (nil hides speak affordances).
    @Entry var speechService: SpeechService? = nil
}

extension View {
    /// Wire speech into the Spanish-text contract («Произнести», tap = speak)
    /// and the environment — only when a Spanish voice is installed.
    func spanishSpeech(_ speech: SpeechService?) -> some View {
        Group {
            if let speech, speech.hasSpanishVoice {
                self
                    .spanishSpanAction(SpanishSpanAction(id: "speak", title: "Произнести",
                                                         systemImage: "speaker.wave.2", isPrimary: true) { text in
                        speech.speak(text, context: .content)
                    })
                    .environment(\.speechService, speech)
            } else {
                self
            }
        }
    }

    /// One-time hint that the Ring/Silent switch can mute speech.
    func speechSilenceHint() -> some View { modifier(SilenceHint()) }
}

private struct SilenceHint: ViewModifier {
    @Environment(\.speechService) private var speech

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let speech, speech.showsSilenceHint {
                HStack(alignment: .top, spacing: LoritoSpacing.sm) {
                    Image(systemName: "speaker.slash")
                        .foregroundStyle(LoritoColor.accent)
                        .accessibilityHidden(true)
                    Text("Нет звука? Выключите беззвучный режим или включите «Звук в беззвучном режиме» в настройках.")
                        .font(LoritoFont.caption)
                        .foregroundStyle(LoritoColor.textPrimary)
                    Spacer(minLength: 0)
                    Button("Понятно") { speech.showsSilenceHint = false }
                        .font(LoritoFont.bodyStrong)
                        .foregroundStyle(LoritoColor.accent)
                        .frame(minHeight: LoritoLayout.minTouchTarget)
                }
                .padding(LoritoSpacing.md)
                .background(LoritoColor.surfaceRaised, in: RoundedRectangle(cornerRadius: LoritoRadius.md, style: .continuous))
                .loritoElevation()
                .padding(.horizontal, LoritoSpacing.screenGutter)
                .padding(.top, LoritoSpacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("silenceHint")
            }
        }
    }
}

/// Speaker button for a surface's main Spanish content (hidden without a
/// Spanish voice or without speakable text).
struct SurfaceSpeakButton: View {
    let spans: [String]
    var tone: SpeakButton.Tone = .surface
    @Environment(\.speechService) private var speech

    private var text: String { spans.joined(separator: ", ") }

    var body: some View {
        if let speech, !spans.isEmpty {
            SpeakButton(isSpeaking: speech.speakingText == SpeakableText.extract(text), tone: tone) {
                speech.speak(text, context: .content)
            }
        }
    }
}
