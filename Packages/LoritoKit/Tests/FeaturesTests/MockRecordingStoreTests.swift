import Foundation
import Testing
@testable import Features

@Suite("Mock recordings stay local")
struct MockRecordingStoreTests {
    @Test("Latest 20 kept; deleting an attempt deletes its recordings")
    func pruneAndDelete() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = MockRecordingStore(root: root)
        let attempts = (0..<3).map { _ in UUID() }
        var n = 0
        for a in attempts {
            for i in 0..<9 {
                let url = try store.url(attempt: a, item: "s\(i)")
                try Data([0]).write(to: url)
                try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: Double(n))], ofItemAtPath: url.path)
                n += 1
            }
        }
        store.prune()
        #expect(attempts.reduce(0) { $0 + store.recordings(attempt: $1).count } == 20)
        #expect(store.recordings(attempt: attempts[0]).count == 2)      // oldest pruned
        store.deleteRecordings(attempt: attempts[2])
        #expect(store.recordings(attempt: attempts[2]).isEmpty)
        #expect(root.path.contains(FileManager.default.temporaryDirectory.path))
    }
}
