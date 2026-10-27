import Foundation

/// Work done whenever the app returns to the foreground: widgets, analytics
/// flush and — so streak, freeze and at-risk copy stays current — a reminder
/// reschedule (streak-protection). Reminders are planned days ahead, so copy
/// for days the app does not run remains best-effort.
@MainActor
enum ForegroundRefresh {
    static func run(publishWidgets: () -> Void,
                    flushAnalytics: @escaping @MainActor () async -> Void,
                    rescheduleReminders: @escaping @MainActor () async -> Void) async {
        publishWidgets()
        async let flush: Void = flushAnalytics()
        async let reschedule: Void = rescheduleReminders()
        _ = await (flush, reschedule)
    }
}
