import Foundation

public struct UserKnowledgeState: Equatable, Sendable {
    public var topicMastery: [String: TopicMastery]
    public var questionHistory: [String: QuestionHistory]

    public init(
        topicMastery: [String: TopicMastery] = [:],
        questionHistory: [String: QuestionHistory] = [:]
    ) {
        self.topicMastery = topicMastery
        self.questionHistory = questionHistory
    }
}

public struct TopicMastery: Equatable, Sendable {
    public let topicId: String
    public let score: Double
    public let lastUpdated: Date

    public init(topicId: String, score: Double, lastUpdated: Date) {
        self.topicId = topicId
        self.score = score
        self.lastUpdated = lastUpdated
    }
}

public struct QuestionHistory: Equatable, Sendable {
    public let questionId: String
    public let lastSeen: Date
    public let correctness: Double
    public let confidence: Double

    public init(questionId: String, lastSeen: Date, correctness: Double, confidence: Double) {
        self.questionId = questionId
        self.lastSeen = lastSeen
        self.correctness = correctness
        self.confidence = confidence
    }
}

public struct QuestionOutcome: Equatable, Sendable {
    public let questionId: String
    public let topicId: String
    public let isCorrect: Bool
    public let confidence: Double
    public let seenAt: Date

    public init(
        questionId: String,
        topicId: String,
        isCorrect: Bool,
        confidence: Double,
        seenAt: Date
    ) {
        self.questionId = questionId
        self.topicId = topicId
        self.isCorrect = isCorrect
        self.confidence = confidence
        self.seenAt = seenAt
    }
}

public struct UserModelConfig: Equatable, Sendable {
    public let halfLifeDays: Double
    public let learningRate: Double
    public let initialTopicScore: Double

    public static let `default` = UserModelConfig(halfLifeDays: 7, learningRate: 0.2, initialTopicScore: 0.2)

    public init(halfLifeDays: Double, learningRate: Double, initialTopicScore: Double) {
        self.halfLifeDays = halfLifeDays
        self.learningRate = learningRate
        self.initialTopicScore = initialTopicScore
    }
}

public enum UserModel {
    public static func apply(
        _ outcome: QuestionOutcome,
        to state: UserKnowledgeState,
        config: UserModelConfig = .default
    ) -> UserKnowledgeState {
        let previousMastery = state.topicMastery[outcome.topicId]
            ?? TopicMastery(topicId: outcome.topicId, score: config.initialTopicScore, lastUpdated: outcome.seenAt)
        let effectiveNow = max(outcome.seenAt, previousMastery.lastUpdated)
        let decayedScore = decayScore(from: previousMastery, now: effectiveNow, config: config)
        let performance = (outcome.isCorrect ? 1.0 : 0.0) * clamp(outcome.confidence)
        let updatedScore = clamp(decayedScore + (performance - decayedScore) * config.learningRate)

        var updatedState = state
        updatedState.topicMastery[outcome.topicId] = TopicMastery(
            topicId: outcome.topicId,
            score: updatedScore,
            lastUpdated: effectiveNow
        )
        updatedState.questionHistory[outcome.questionId] = QuestionHistory(
            questionId: outcome.questionId,
            lastSeen: outcome.seenAt,
            correctness: outcome.isCorrect ? 1.0 : 0.0,
            confidence: clamp(outcome.confidence)
        )
        return updatedState
    }

    public static func decayScore(from mastery: TopicMastery, now: Date, config: UserModelConfig = .default) -> Double {
        guard config.halfLifeDays > 0 else {
            return clamp(mastery.score)
        }
        let days = max(0, now.timeIntervalSince(mastery.lastUpdated)) / 86_400
        let lambda = log(2) / config.halfLifeDays
        return clamp(mastery.score * exp(-lambda * days))
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
