import Foundation
import Testing
import Domain
@testable import WidgetSupport

private func snapshot(streak: Int, version: Int = WidgetSnapshot.currentVersion) -> WidgetSnapshot {
    WidgetSnapshot(version: version, generatedAt: Date(timeIntervalSince1970: 1_800_000_000),
                   day: Date(timeIntervalSince1970: 1_799_971_200), currentStreak: streak, studiedToday: false,
                   dueToday: 8, newToday: 4, remainingToday: 12, wordOfDay: nil, questions: [])
}

private func tempDir() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("Widget snapshot store")
struct WidgetSnapshotStoreTests {
    @Test("Writes the snapshot file and replaces it atomically")
    func writeAndReplace() throws {
        let dir = tempDir()
        let store = WidgetSnapshotStore(directory: dir)
        try store.write(snapshot(streak: 13))
        #expect(store.read()?.currentStreak == 13)
        try store.write(snapshot(streak: 14))
        #expect(store.read()?.currentStreak == 14)
        // Only the snapshot file remains (no temp leftovers from the atomic write).
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files == [WidgetSnapshotStore.fileName])
    }

    @Test("Missing file or unknown version reads as nil (neutral widget state)")
    func neutral() throws {
        let store = WidgetSnapshotStore(directory: tempDir())
        #expect(store.read() == nil)
        try store.write(snapshot(streak: 1, version: 99))
        #expect(store.read() == nil)
        try Data("not json".utf8).write(to: store.fileURL)
        #expect(store.read() == nil)
    }
}

@Suite("Widget practice answers")
struct PracticeAnswerStoreTests {
    @Test("Choosing an option records it; next advances and clears; day change resets")
    func flow() throws {
        let defaults = try #require(UserDefaults(suiteName: "lorito.tests.\(UUID().uuidString)"))
        let store = PracticeAnswerStore(defaults: defaults)
        let day = Date(timeIntervalSince1970: 1_799_971_200)
        #expect(store.state(for: day) == .init(index: 0, chosen: nil))
        store.choose("la", on: day)
        #expect(store.state(for: day) == .init(index: 0, chosen: "la"))
        store.next(on: day, count: 3)
        #expect(store.state(for: day) == .init(index: 1, chosen: nil))
        store.next(on: day, count: 3); store.next(on: day, count: 3)
        #expect(store.state(for: day).index == 0)            // wraps
        #expect(store.state(for: day.addingTimeInterval(86_400)) == .init(index: 0, chosen: nil))
    }
}

@Suite("Widget day state")
struct WidgetDayStateTests {
    private static let cal = Calendar.utcDay
    private static let day = cal.date(from: DateComponents(year: 2026, month: 10, day: 27))!

    private static func snap(streak: Int, studied: Bool, remaining: Int = 12) -> WidgetSnapshot {
        WidgetSnapshot(generatedAt: day, day: day, currentStreak: streak, studiedToday: studied,
                       dueToday: 8, newToday: remaining - 8, remainingToday: remaining, wordOfDay: nil, questions: [])
    }

    private static func at(daysLater: Int, hour: Int = 10) -> Date {
        cal.date(byAdding: DateComponents(day: daysLater, hour: hour), to: day)!
    }

    @Test("Same day: snapshot values as is; streak at risk when not studied")
    func sameDay() {
        let s = WidgetDayState.make(snapshot: Self.snap(streak: 13, studied: false), now: Self.at(daysLater: 0))
        #expect(s == .init(streak: 13, studiedToday: false, remainingToday: 12, streakAtRisk: true))
        let studied = WidgetDayState.make(snapshot: Self.snap(streak: 13, studied: true), now: Self.at(daysLater: 0))
        #expect(!studied.streakAtRisk && studied.studiedToday)
    }

    @Test("Next day without the app: not studied, counts unknown, streak kept if studied yesterday")
    func nextDay() {
        let kept = WidgetDayState.make(snapshot: Self.snap(streak: 13, studied: true), now: Self.at(daysLater: 1))
        #expect(kept == .init(streak: 13, studiedToday: false, remainingToday: nil, streakAtRisk: true))
        let broken = WidgetDayState.make(snapshot: Self.snap(streak: 13, studied: false), now: Self.at(daysLater: 1))
        #expect(broken.streak == 0 && !broken.streakAtRisk)
        let later = WidgetDayState.make(snapshot: Self.snap(streak: 13, studied: true), now: Self.at(daysLater: 3))
        #expect(later.streak == 0)
    }

    @Test("Next refresh dates: local midnight and UTC day start, both in the future, sorted")
    func refreshDates() {
        var moscow = Calendar(identifier: .gregorian)
        moscow.timeZone = TimeZone(identifier: "Europe/Moscow")!
        let now = Self.at(daysLater: 0, hour: 10)
        let dates = WidgetDayState.nextRefreshDates(after: now, localCalendar: moscow)
        #expect(dates.count == 2)
        #expect(dates.allSatisfy { $0 > now })
        #expect(dates == dates.sorted())
        #expect(dates.contains(Self.at(daysLater: 1, hour: 0)))           // next UTC day
    }
}
