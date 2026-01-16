import Foundation

public struct Topic: Equatable, Codable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct FactCard: Equatable, Codable, Sendable {
    public let id: String
    public let text: String
    public let mediaId: String?
    public let provenance: String?

    public init(id: String, text: String, mediaId: String? = nil, provenance: String? = nil) {
        self.id = id
        self.text = text
        self.mediaId = mediaId
        self.provenance = provenance
    }
}

public struct QuestionCard: Equatable, Codable, Sendable {
    public let id: String
    public let prompt: String
    public let choices: [String]?
    public let answer: String
    public let explanation: String?
    public let difficulty: Int

    public init(
        id: String,
        prompt: String,
        choices: [String]? = nil,
        answer: String,
        explanation: String? = nil,
        difficulty: Int
    ) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.answer = answer
        self.explanation = explanation
        self.difficulty = difficulty
    }
}

public enum FeedItem: Equatable, Sendable {
    case fact(FactCard)
    case question(QuestionCard)
}

public struct FeedFixture: Equatable, Codable, Sendable {
    public let topic: Topic
    public let facts: [FactCard]
    public let questions: [QuestionCard]

    public init(topic: Topic, facts: [FactCard], questions: [QuestionCard]) {
        self.topic = topic
        self.facts = facts
        self.questions = questions
    }
}
