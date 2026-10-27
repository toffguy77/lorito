import WidgetKit
import Domain
import WidgetSupport

/// A moment in a widget timeline: the snapshot (nil = neutral state) and what
/// it means at `date`.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    var state: WidgetDayState? { snapshot.map { WidgetDayState.make(snapshot: $0, now: date) } }
}

/// Reads the App Group snapshot; entries now and at the next day boundaries
/// so day-dependent content resets without the app running.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: context.isPreview ? .preview : WidgetSnapshotStore.shared?.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshotStore.shared?.read()
        let dates = [now] + WidgetDayState.nextRefreshDates(after: now)
        completion(Timeline(entries: dates.map { SnapshotEntry(date: $0, snapshot: snapshot) }, policy: .atEnd))
    }
}

extension WidgetSnapshot {
    /// Gallery / placeholder content.
    static let preview = WidgetSnapshot(
        generatedAt: Date(), day: Date(), currentStreak: 13, studiedToday: false,
        dueToday: 12, newToday: 6, remainingToday: 18,
        wordOfDay: .init(spanish: "el águila", note: "Род существительных", cardID: "A1-07"),
        questions: [.init(id: "preview", prompt: "Какой артикль? *___ idioma*", options: ["el", "la"],
                          answer: "el", cardID: "A1-07")]
    )
}
