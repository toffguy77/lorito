// A practice exercise: structured metadata + a type-specific payload.
//
// Decoded from the compiled content bundle, where each exercise is a flat JSON
// object with a `type` discriminator and type-specific keys. Pure value type —
// no SwiftUI/SwiftData/CloudKit.

/// A left↔right pairing for `matching` exercises.
public struct MatchPair: Codable, Sendable, Hashable {
    public let left: String
    public let right: String
    public init(left: String, right: String) {
        self.left = left
        self.right = right
    }
}

/// A label↔image pairing for `picture-matching` exercises (image names a bundled asset).
public struct PictureOption: Codable, Sendable, Hashable {
    public let image: String
    public let label: String
    public init(image: String, label: String) {
        self.image = image
        self.label = label
    }
}

/// The type-specific payload. `isAutoChecked` distinguishes types the engine can
/// grade from `freeResponse`, which the user self-assesses.
public enum ExerciseKind: Sendable, Hashable {
    case multipleChoice(options: [String], answer: String)
    case fillInTheBlank(answer: String, accept: [String])
    case matching(pairs: [MatchPair])
    case wordOrder(tokens: [String], answer: String, accept: [String])
    case pictureMatching(options: [PictureOption])
    case freeResponse(answer: String, accept: [String])

    /// The wire `type` string used in the content bundle.
    public var typeName: String {
        switch self {
        case .multipleChoice: return "multiple-choice"
        case .fillInTheBlank: return "fill-in-the-blank"
        case .matching: return "matching"
        case .wordOrder: return "word-order"
        case .pictureMatching: return "picture-matching"
        case .freeResponse: return "free-response"
        }
    }

    /// True when the engine decides correctness; false for self-assessed types.
    public var isAutoChecked: Bool {
        if case .freeResponse = self { return false }
        return true
    }
}

public struct Exercise: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let level: CEFRLevel
    public let themeID: String
    /// The card this exercise drills; correctness feeds this card's review.
    public let card: String
    public let prompt: String       // Markdown
    public let explanation: String  // Markdown, shown after checking/revealing
    public let kind: ExerciseKind

    /// Alias matching the card-keyed vocabulary used across the SRS.
    public var cardID: String { card }

    public init(
        id: String,
        level: CEFRLevel,
        themeID: String,
        card: String,
        prompt: String,
        explanation: String,
        kind: ExerciseKind
    ) {
        self.id = id
        self.level = level
        self.themeID = themeID
        self.card = card
        self.prompt = prompt
        self.explanation = explanation
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case id, level, themeID, card, type, prompt, explanation
        case options, answer, accept, pairs, tokens
    }

    public enum DecodingError: Error, Equatable {
        case unknownType(String)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        level = try c.decode(CEFRLevel.self, forKey: .level)
        themeID = try c.decode(String.self, forKey: .themeID)
        card = try c.decode(String.self, forKey: .card)
        prompt = try c.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        explanation = try c.decodeIfPresent(String.self, forKey: .explanation) ?? ""

        let type = try c.decode(String.self, forKey: .type)
        func strings(_ k: CodingKeys) throws -> [String] {
            try c.decodeIfPresent([String].self, forKey: k) ?? []
        }
        switch type {
        case "multiple-choice":
            kind = .multipleChoice(options: try strings(.options),
                                   answer: try c.decode(String.self, forKey: .answer))
        case "fill-in-the-blank":
            kind = .fillInTheBlank(answer: try c.decode(String.self, forKey: .answer),
                                   accept: try strings(.accept))
        case "matching":
            kind = .matching(pairs: try c.decodeIfPresent([MatchPair].self, forKey: .pairs) ?? [])
        case "word-order":
            kind = .wordOrder(tokens: try strings(.tokens),
                              answer: try c.decode(String.self, forKey: .answer),
                              accept: try strings(.accept))
        case "picture-matching":
            kind = .pictureMatching(options: try c.decodeIfPresent([PictureOption].self, forKey: .options) ?? [])
        case "free-response":
            kind = .freeResponse(answer: try c.decode(String.self, forKey: .answer),
                                 accept: try strings(.accept))
        default:
            throw DecodingError.unknownType(type)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(level, forKey: .level)
        try c.encode(themeID, forKey: .themeID)
        try c.encode(card, forKey: .card)
        try c.encode(prompt, forKey: .prompt)
        try c.encode(explanation, forKey: .explanation)
        try c.encode(kind.typeName, forKey: .type)
        switch kind {
        case let .multipleChoice(options, answer):
            try c.encode(options, forKey: .options)
            try c.encode(answer, forKey: .answer)
        case let .fillInTheBlank(answer, accept):
            try c.encode(answer, forKey: .answer)
            try c.encode(accept, forKey: .accept)
        case let .matching(pairs):
            try c.encode(pairs, forKey: .pairs)
        case let .wordOrder(tokens, answer, accept):
            try c.encode(tokens, forKey: .tokens)
            try c.encode(answer, forKey: .answer)
            try c.encode(accept, forKey: .accept)
        case let .pictureMatching(options):
            try c.encode(options, forKey: .options)
        case let .freeResponse(answer, accept):
            try c.encode(answer, forKey: .answer)
            try c.encode(accept, forKey: .accept)
        }
    }
}
