import Foundation
import SwiftData

// SwiftData @Model records. Kept CloudKit-friendly: every stored property has a
// default value and there are no unique constraints (CloudKit sync forbids them).

@Model
public final class SettingsRecord {
    public var targetLevelRaw: String?
    public var selectedThemeIDs: [String]
    public var dailyNewCardCount: Int
    public var remindersEnabled: Bool
    public var reminderMinutes: [Int]
    public var didCompleteOnboarding: Bool

    public init(
        targetLevelRaw: String? = nil,
        selectedThemeIDs: [String] = [],
        dailyNewCardCount: Int = 1,
        remindersEnabled: Bool = false,
        reminderMinutes: [Int] = [],
        didCompleteOnboarding: Bool = false
    ) {
        self.targetLevelRaw = targetLevelRaw
        self.selectedThemeIDs = selectedThemeIDs
        self.dailyNewCardCount = dailyNewCardCount
        self.remindersEnabled = remindersEnabled
        self.reminderMinutes = reminderMinutes
        self.didCompleteOnboarding = didCompleteOnboarding
    }
}

@Model
public final class ReviewRecord {
    public var cardID: String
    public var easeFactor: Double
    public var interval: Int
    public var repetitions: Int
    public var dueDate: Date
    public var lastGrade: String?
    public var statusRaw: String

    public init(
        cardID: String = "",
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        dueDate: Date = .distantPast,
        lastGrade: String? = nil,
        statusRaw: String = "new"
    ) {
        self.cardID = cardID
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.lastGrade = lastGrade
        self.statusRaw = statusRaw
    }
}

@Model
public final class EventRecord {
    public var eventID: UUID
    public var cardID: String
    public var date: Date
    public var grade: String?

    public init(eventID: UUID = UUID(), cardID: String = "", date: Date = .distantPast, grade: String? = nil) {
        self.eventID = eventID
        self.cardID = cardID
        self.date = date
        self.grade = grade
    }
}
