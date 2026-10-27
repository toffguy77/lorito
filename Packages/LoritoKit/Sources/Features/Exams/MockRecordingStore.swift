import Foundation

/// Speaking-task recordings: stored only in the app's local container (never
/// synced), at most 2 minutes each, the latest 20 kept, deleted with their attempt.
public struct MockRecordingStore: Sendable {
    public static let maxDuration: TimeInterval = 120
    public static let keepLatest = 20

    let root: URL

    public init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MockRecordings", isDirectory: true)
    }

    /// Where a new recording for `item` of `attempt` goes (directory created).
    public func url(attempt: UUID, item: String) throws -> URL {
        let dir = root.appendingPathComponent(attempt.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var url = dir.appendingPathComponent("\(item).m4a")
        // Exclude from iCloud backup as well: recordings stay on this device.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return url
    }

    public func recordings(attempt: UUID) -> [URL] {
        let dir = root.appendingPathComponent(attempt.uuidString, isDirectory: true)
        return ((try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []).sorted { $0.path < $1.path }
    }

    public func deleteRecordings(attempt: UUID) {
        try? FileManager.default.removeItem(at: root.appendingPathComponent(attempt.uuidString, isDirectory: true))
    }

    /// Keep only the newest `keepLatest` recordings across attempts.
    public func prune() {
        let fm = FileManager.default
        let dirs = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        let files = dirs.flatMap { (try? fm.contentsOfDirectory(at: $0, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [] }
        let dated = files.map { ($0, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
        for (url, _) in dated.sorted(by: { $0.1 > $1.1 }).dropFirst(Self.keepLatest) {
            try? fm.removeItem(at: url)
        }
    }
}
