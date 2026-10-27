import Foundation
import Speech
import AVFoundation
import Domain

/// Whether a `speak` exercise can be checked automatically.
public enum RecognitionAvailability: Sendable, Equatable {
    case available
    /// Permissions not asked yet (show the explanation first).
    case notDetermined
    /// The user refused microphone or speech recognition (remembered; never re-prompted).
    case denied
    /// No on-device Spanish recognition on this device.
    case unsupported
}

/// Speech recognition for `speak` exercises — on device only (a fake in tests).
@MainActor
public protocol SpeechRecognizing: AnyObject {
    var availability: RecognitionAvailability { get }
    /// Input level 0…1 while recording (for the meter).
    var level: Float { get }
    /// Asks for microphone + speech permission (after the explanation screen).
    func requestPermissions() async -> Bool
    /// Records until `stop()` or `maxDuration`; returns the best transcript first, then alternatives.
    func recognize(maxDuration: TimeInterval) async throws -> [String]
    func stop()
}

/// `SFSpeechRecognizer` for es-ES with `requiresOnDeviceRecognition`; refuses to
/// start unless `supportsOnDeviceRecognition`. Audio is never sent to a server.
/// Recording uses a play-and-record session only while recording and restores
/// the previous session afterwards.
@MainActor
@Observable
public final class SystemSpeechRecognizer: SpeechRecognizing {
    static let deniedKey = "speech.permissionDenied"
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    private let defaults: UserDefaults
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    public private(set) var level: Float = 0

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var availability: RecognitionAvailability {
        guard let recognizer, recognizer.supportsOnDeviceRecognition else { return .unsupported }
        if defaults.bool(forKey: Self.deniedKey) { return .denied }
        let speech = SFSpeechRecognizer.authorizationStatus()
        let mic = AVAudioApplication.shared.recordPermission
        if speech == .denied || speech == .restricted || mic == .denied { return .denied }
        if speech == .authorized && mic == .granted { return .available }
        return .notDetermined
    }

    public func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
        }
        let mic = await AVAudioApplication.requestRecordPermission()
        let ok = speech == .authorized && mic
        if !ok { defaults.set(true, forKey: Self.deniedKey) }
        return ok
    }

    public func recognize(maxDuration: TimeInterval) async throws -> [String] {
        guard availability == .available, let recognizer else { throw RecognitionError.unavailable }
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        let previous = (session.category, session.mode, session.categoryOptions)
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true)
        defer {
            try? session.setCategory(previous.0, mode: previous.1, options: previous.2)
        }
        #endif
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            request.append(buffer)
            let rms = Self.rms(buffer)
            Task { @MainActor in self?.level = rms }
        }
        engine.prepare()
        try engine.start()
        self.engine = engine
        self.request = request
        defer {
            engine.stop()
            input.removeTap(onBus: 0)
            self.engine = nil
            self.request = nil
            self.level = 0
        }
        let stopper = Task { [weak self] in
            try? await Task.sleep(for: .seconds(maxDuration))
            await MainActor.run { self?.stop() }
        }
        defer { stopper.cancel() }
        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<[String], Error>) in
            var resumed = false
            task = recognizer.recognitionTask(with: request) { result, error in
                guard !resumed else { return }
                if let result, result.isFinal {
                    resumed = true
                    let best = result.bestTranscription.formattedString
                    let alternatives = result.transcriptions.map(\.formattedString).filter { $0 != best }
                    c.resume(returning: [best] + alternatives.prefix(4))
                } else if let error {
                    resumed = true
                    c.resume(throwing: error)
                }
            }
        }
    }

    public func stop() {
        request?.endAudio()
    }

    public enum RecognitionError: Error { case unavailable }

    nonisolated static func rms(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += data[i] * data[i] }
        return min(1, sqrt(sum / Float(buffer.frameLength)) * 10)
    }
}
