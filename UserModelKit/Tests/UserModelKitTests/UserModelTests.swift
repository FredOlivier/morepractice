import XCTest
@testable import UserModelKit

final class UserModelTests: XCTestCase {
    func testDecayHalfLife() {
        let start = Date(timeIntervalSince1970: 0)
        let later = start.addingTimeInterval(7 * 86_400)
        let mastery = TopicMastery(topicId: "topic-1", score: 1.0, lastUpdated: start)
        let decayed = UserModel.decayScore(from: mastery, now: later, config: .default)
        XCTAssertEqual(decayed, 0.5, accuracy: 0.0001)
    }

    func testApplyOutcomeUpdatesMasteryAndHistory() {
        let seenAt = Date(timeIntervalSince1970: 1_000)
        let outcome = QuestionOutcome(
            questionId: "question-1",
            topicId: "topic-1",
            isCorrect: true,
            confidence: 0.8,
            seenAt: seenAt
        )
        let updated = UserModel.apply(outcome, to: UserKnowledgeState(), config: .default)

        let mastery = updated.topicMastery["topic-1"]
        XCTAssertEqual(mastery?.lastUpdated, seenAt)
        XCTAssertEqual(mastery?.score ?? 0, 0.32, accuracy: 0.0001)

        let history = updated.questionHistory["question-1"]
        XCTAssertEqual(history?.lastSeen, seenAt)
        XCTAssertEqual(history?.correctness ?? 0, 1.0, accuracy: 0.0001)
        XCTAssertEqual(history?.confidence ?? 0, 0.8, accuracy: 0.0001)
    }

    func testApplyOutcomeUsesDecayedScore() {
        let start = Date(timeIntervalSince1970: 0)
        let seenAt = start.addingTimeInterval(7 * 86_400)
        let previous = TopicMastery(topicId: "topic-1", score: 1.0, lastUpdated: start)
        let state = UserKnowledgeState(topicMastery: ["topic-1": previous])
        let outcome = QuestionOutcome(
            questionId: "question-2",
            topicId: "topic-1",
            isCorrect: true,
            confidence: 1.0,
            seenAt: seenAt
        )

        let updated = UserModel.apply(outcome, to: state, config: .default)
        XCTAssertEqual(updated.topicMastery["topic-1"]?.score ?? 0, 0.6, accuracy: 0.0001)
    }
}
