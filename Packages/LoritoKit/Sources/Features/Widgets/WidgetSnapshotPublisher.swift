import Foundation
import Domain
import WidgetSupport
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Publishes the widget snapshot to the App Group and reloads widget
/// timelines. Called on the same triggers as reminder rescheduling (launch,
/// foreground / day rollover) and after study or exercise sessions. Reads the
/// user-data store only.
@MainActor
enum WidgetSnapshotPublisher {
    static func makeSnapshot(store: UserDataStore, catalog: ContentCatalog, today: Date) -> WidgetSnapshot {
        let plan = TodayModel(store: store, catalog: catalog, today: { today })
        let settings = (try? store.loadSettings()) ?? .default
        let events = (try? store.allEvents()) ?? []
        let inScopeThemes = Set(
            SelectionScope.inScopeCards(targetLevel: settings.targetLevel,
                                        selectedThemeIDs: Set(settings.selectedThemeIDs), in: catalog).map(\.themeID)
        )
        return WidgetSnapshot.make(
            stats: StatsCalculator.compute(events: events, today: today),
            dueToday: plan.dueRemaining,
            newToday: plan.newRemaining,
            trap: plan.trap,
            trapNote: plan.trap.flatMap { catalog.card(id: $0.cardID)?.title },
            exercises: catalog.exercises.filter { inScopeThemes.contains($0.themeID) },
            today: today
        )
    }

    static func publish(
        store: UserDataStore,
        catalog: ContentCatalog,
        to target: WidgetSnapshotStore? = .shared,
        reloadTimelines: Bool = true
    ) {
        guard let target else { return }   // no App Group entitlement (e.g. tests, unsigned builds)
        try? target.write(makeSnapshot(store: store, catalog: catalog, today: Date()))
        #if canImport(WidgetKit)
        if reloadTimelines { WidgetCenter.shared.reloadAllTimelines() }
        #endif
    }
}
