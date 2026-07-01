import Foundation
import SwiftData

// SwiftData @Model records. CloudKit-friendly: every stored property is either
// optional or has an INLINE default value (CloudKit checks the attribute itself,
// not the initializer's parameter defaults), and there are no unique constraints
// (CloudKit sync forbids them).

@Model
public final class SettingsRecord {
    public var targetLevelRaw: String?
    public var selectedThemeIDs: [String] = []
    public var dailyNewCardCount: Int = 1
    public var remindersEnabled: Bool = false
    public var reminderMinutes: [Int] = []
    public var didCompleteOnboarding: Bool = false

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
    public var cardID: String = ""
    public var easeFactor: Double = 2.5
    public var interval: Int = 0
    public var repetitions: Int = 0
    public var dueDate: Date = Date.distantPast
    public var lastGrade: String?
    public var statusRaw: String = "new"

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
    public var eventID: UUID = UUID()
    public var cardID: String = ""
    public var date: Date = Date.distantPast
    public var grade: String?

    public init(eventID: UUID = UUID(), cardID: String = "", date: Date = .distantPast, grade: String? = nil) {
        self.eventID = eventID
        self.cardID = cardID
        self.date = date
        self.grade = grade
    }
}

@Model
public final class AttemptRecord {
    public var attemptID: UUID = UUID()
    public var exerciseID: String = ""
    public var cardID: String = ""
    public var date: Date = Date.distantPast
    public var correct: Bool = false
    public var grade: String?

    public init(
        attemptID: UUID = UUID(),
        exerciseID: String = "",
        cardID: String = "",
        date: Date = .distantPast,
        correct: Bool = false,
        grade: String? = nil
    ) {
        self.attemptID = attemptID
        self.exerciseID = exerciseID
        self.cardID = cardID
        self.date = date
        self.correct = correct
        self.grade = grade
    }
}
