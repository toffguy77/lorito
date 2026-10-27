import SwiftUI

/// Speaker button (44×44 pt, label «Произнести»); shows a filled icon while speaking.
public struct SpeakButton: View {
    public enum Tone: Sendable { case surface, ink }

    private let isSpeaking: Bool
    private let tone: Tone
    private let action: () -> Void

    public init(isSpeaking: Bool, tone: Tone = .surface, action: @escaping () -> Void) {
        self.isSpeaking = isSpeaking
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tone == .ink ? LoritoColor.highlight : LoritoColor.accent)
                .frame(width: LoritoLayout.minTouchTarget, height: LoritoLayout.minTouchTarget)
                .background(tone == .ink ? LoritoColor.inkRaised : LoritoColor.accentSoft, in: Circle())
                .symbolEffect(.variableColor.iterative, isActive: isSpeaking)
        }
        .buttonStyle(.plain)
        .loritoHover()
        .accessibilityLabel("Произнести")
        .accessibilityAddTraits(isSpeaking ? .updatesFrequently : [])
    }
}
