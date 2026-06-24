import Foundation
import Observation
import UserNotifications
import Domain

/// Holds the pending deep-link route from a tapped reminder. The app observes
/// `openToday` to navigate to the Today/study entry from terminated, background,
/// or foreground states.
@MainActor
@Observable
public final class RemindersRouter {
    public var openToday = false

    public init() {}

    /// Apply a route value (e.g. from a notification's `userInfo`).
    public func handle(route: String?) {
        if route == ReminderRoute.today { openToday = true }
    }

    public func handle(userInfo: [AnyHashable: Any]) {
        handle(route: userInfo["route"] as? String)
    }

    public func consume() { openToday = false }
}

/// `UNUserNotificationCenter` delegate that routes a tapped reminder to Today.
public final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: RemindersRouter

    public init(router: RemindersRouter) {
        self.router = router
    }

    // Tap handling (works from terminated/background/foreground).
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let route = response.notification.request.content.userInfo["route"] as? String
        let router = self.router
        Task { @MainActor in router.handle(route: route) }
        completionHandler()
    }

    // Show banners while in the foreground too.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
