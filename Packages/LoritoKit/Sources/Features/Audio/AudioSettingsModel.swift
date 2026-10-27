import Foundation
import Observation
import Domain

/// Settings «Звук»: Spanish variant, speed and silent-mode playback, persisted
/// as synced user settings.
@MainActor
@Observable
public final class AudioSettingsModel {
    private let store: UserDataStore
    public private(set) var settings: UserSettings

    public init(store: UserDataStore) {
        self.store = store
        self.settings = (try? store.loadSettings()) ?? .default
    }

    public var variant: SpanishVariant {
        get { settings.spanishVariant }
        set { update { $0.spanishVariant = newValue } }
    }

    public var rate: SpeechRate {
        get { settings.speechRate }
        set { update { $0.speechRate = newValue } }
    }

    public var playWhenSilent: Bool {
        get { settings.playAudioWhenSilent }
        set { update { $0.playAudioWhenSilent = newValue } }
    }

    /// Load fresh, change, save — so other settings written elsewhere survive.
    private func update(_ change: (inout UserSettings) -> Void) {
        var s = (try? store.loadSettings()) ?? .default
        change(&s)
        try? store.saveSettings(s)
        settings = s
    }
}
