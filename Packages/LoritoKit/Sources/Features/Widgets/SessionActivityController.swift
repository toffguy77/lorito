import Foundation
import Domain
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import WidgetSupport
#endif

/// Owns the study-session Live Activity: start on session open (when Live
/// Activities are enabled), update after each grade with position, total and
/// a minutes-left estimate, end on completion or exit. At most one at a time.
@MainActor
final class SessionActivityController {
    private var lastGradeAt: Date?
    private var secondsPerCard: [Double] = []

    /// The running activity's id. `Activity` isn't Sendable, so tasks look it
    /// up by id instead of capturing it.
    private var activityID: String?

    func start(total: Int) {
        lastGradeAt = Date()
        secondsPerCard = []
        #if canImport(ActivityKit) && os(iOS)
        endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled, total > 0 else { return }
        let state = SessionActivityAttributes.ContentState(
            position: 0, total: total, minutesLeft: SessionPace.minutesLeft(remaining: total, secondsPerCard: []))
        activityID = (try? Activity.request(attributes: SessionActivityAttributes(),
                                            content: ActivityContent(state: state, staleDate: nil)))?.id
        #endif
    }

    func update(position: Int, total: Int) {
        let now = Date()
        if let last = lastGradeAt { secondsPerCard.append(now.timeIntervalSince(last)) }
        lastGradeAt = now
        #if canImport(ActivityKit) && os(iOS)
        guard let id = activityID else { return }
        let state = SessionActivityAttributes.ContentState(
            position: position, total: total,
            minutesLeft: SessionPace.minutesLeft(remaining: total - position, secondsPerCard: secondsPerCard))
        Task.detached {
            for activity in Activity<SessionActivityAttributes>.activities where activity.id == id {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
        #endif
    }

    func end() {
        #if canImport(ActivityKit) && os(iOS)
        guard let id = activityID else { return }
        activityID = nil
        let dismissal = Date().addingTimeInterval(120)
        Task.detached {
            for activity in Activity<SessionActivityAttributes>.activities where activity.id == id {
                await activity.end(nil, dismissalPolicy: .after(dismissal))
            }
        }
        #endif
    }

    #if canImport(ActivityKit) && os(iOS)
    /// Single active activity: end any left over (e.g. after a crash).
    /// Ids are captured now so a just-requested activity is never ended.
    private func endAll() {
        activityID = nil
        let stale = Set(Activity<SessionActivityAttributes>.activities.map(\.id))
        guard !stale.isEmpty else { return }
        Task.detached {
            for existing in Activity<SessionActivityAttributes>.activities where stale.contains(existing.id) {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    #endif
}
