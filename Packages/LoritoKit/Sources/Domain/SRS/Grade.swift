// The four self-grades (UI labels: Опять / Трудно / Хорошо / Легко).
public enum Grade: String, Codable, Sendable, CaseIterable {
    case again
    case hard
    case good
    case easy
}
