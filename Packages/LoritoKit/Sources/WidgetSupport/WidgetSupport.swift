import Foundation
import Domain

/// The App Group shared by the app and the widget extension.
public enum AppGroup {
    public static let identifier = "group.com.toffguy.lorito"

    /// The shared container, or nil when the entitlement is missing.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    public static var defaults: UserDefaults? { UserDefaults(suiteName: identifier) }
}

/// Deep links the widgets open.
public enum LoritoDeepLink {
    public static let today = URL(string: "lorito://today")!

    public static func isToday(_ url: URL) -> Bool {
        url.scheme == today.scheme && url.host == today.host
    }
}

/// Reads and atomically writes `widget-snapshot.json` in a directory (the App
/// Group container in the app and extension; a temp dir in tests).
public struct WidgetSnapshotStore: Sendable {
    public static let fileName = "widget-snapshot.json"
    public let fileURL: URL

    public init(directory: URL) {
        self.fileURL = directory.appendingPathComponent(Self.fileName)
    }

    /// The App Group store, or nil without the entitlement.
    public static var shared: WidgetSnapshotStore? {
        AppGroup.containerURL.map(WidgetSnapshotStore.init(directory:))
    }

    public func write(_ snapshot: WidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }

    /// The snapshot, or nil when missing, unreadable, or of an unsupported version.
    public func read() -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        struct Header: Decodable { let version: Int }
        guard let header = try? decoder.decode(Header.self, from: data),
              header.version == WidgetSnapshot.currentVersion else { return nil }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}

/// The interactive question widget's state: which question of the day is
/// shown and the option chosen. Practice only — never touches the SRS.
public struct PracticeAnswerStore {
    public struct State: Equatable, Sendable {
        public let index: Int
        public let chosen: String?

        public init(index: Int, chosen: String?) {
            self.index = index
            self.chosen = chosen
        }
    }

    private let defaults: UserDefaults
    private enum Key {
        static let day = "widget.practice.day"
        static let index = "widget.practice.index"
        static let chosen = "widget.practice.chosen"
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public static var shared: PracticeAnswerStore? { AppGroup.defaults.map(PracticeAnswerStore.init(defaults:)) }

    private static func key(_ day: Date) -> String {
        let c = Calendar.learningDay.dateComponents([.year, .month, .day], from: day)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    /// Today's state; a new day starts at the first question, unanswered.
    public func state(for day: Date) -> State {
        guard defaults.string(forKey: Key.day) == Self.key(day) else { return State(index: 0, chosen: nil) }
        return State(index: defaults.integer(forKey: Key.index), chosen: defaults.string(forKey: Key.chosen))
    }

    public func choose(_ option: String, on day: Date) {
        let current = state(for: day)
        save(day: day, index: current.index, chosen: option)
    }

    public func next(on day: Date, count: Int) {
        let current = state(for: day)
        save(day: day, index: count > 0 ? (current.index + 1) % count : 0, chosen: nil)
    }

    private func save(day: Date, index: Int, chosen: String?) {
        defaults.set(Self.key(day), forKey: Key.day)
        defaults.set(index, forKey: Key.index)
        defaults.set(chosen, forKey: Key.chosen)
    }
}
