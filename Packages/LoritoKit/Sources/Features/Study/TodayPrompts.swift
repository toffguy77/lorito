import Foundation
import Domain

/// A dismissible prompt in Today's prompt slot (onboarding moved the goal and
/// regional-variant questions here; `study-goal` and `regional-variants`
/// register their prompts).
public struct TodayPrompt: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let message: String
    public let actionTitle: String

    public init(id: String, title: String, message: String, actionTitle: String) {
        self.id = id
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
    }
}

/// Picks at most one prompt per Today visit: only after the first completed
/// study session, never a dismissed or answered one, in registration order.
public struct TodayPromptSlot: @unchecked Sendable {
    static let dismissedKey = "today.prompts.dismissed"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// `candidates`: prompts whose question is still open, in priority order.
    public func prompt(candidates: [TodayPrompt], events: [StudyEvent]) -> TodayPrompt? {
        guard events.contains(where: { $0.grade != nil && $0.isCard }) else { return nil }
        let dismissed = Set(defaults.stringArray(forKey: Self.dismissedKey) ?? [])
        return candidates.first { !dismissed.contains($0.id) }
    }

    public func dismiss(_ id: String) {
        var dismissed = defaults.stringArray(forKey: Self.dismissedKey) ?? []
        if !dismissed.contains(id) { dismissed.append(id) }
        defaults.set(dismissed, forKey: Self.dismissedKey)
    }
}
