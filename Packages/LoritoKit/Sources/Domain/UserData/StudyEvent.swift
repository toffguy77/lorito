import Foundation

/// A record of a study interaction, kept for statistics and (later) practice.
public struct StudyEvent: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var cardID: String
    public var date: Date
    public var grade: String?

    public init(id: UUID = UUID(), cardID: String, date: Date, grade: String? = nil) {
        self.id = id
        self.cardID = cardID
        self.date = date
        self.grade = grade
    }
}
