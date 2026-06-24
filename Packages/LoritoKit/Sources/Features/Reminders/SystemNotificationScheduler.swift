import Foundation
import UserNotifications
import Domain

/// Production `NotificationScheduling` backed by `UNUserNotificationCenter`.
/// Maps the pure `ReminderRequest`s onto non-repeating calendar triggers and
/// scopes removal to the reserved reminder identifier prefix.
@MainActor
public final class SystemNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    public init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    public func authorizationStatus() async -> ReminderAuthorization {
        map(await center.notificationSettings().authorizationStatus)
    }

    public func requestAuthorization() async -> ReminderAuthorization {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted ? .authorized : .denied
    }

    public func schedule(_ requests: [ReminderRequest]) async {
        for request in requests {
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.userInfo = ["route": request.route]
            content.sound = .default

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: request.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let unRequest = UNNotificationRequest(identifier: request.id, content: content, trigger: trigger)
            try? await center.add(unRequest)
        }
    }

    public func removeReminders(withPrefix prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func map(_ status: UNAuthorizationStatus) -> ReminderAuthorization {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .provisional: return .provisional
        case .authorized, .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }
}
