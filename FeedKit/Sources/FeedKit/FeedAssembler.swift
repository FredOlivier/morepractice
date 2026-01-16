import Foundation

public struct FeedAssembler: Sendable {
    public init() {}

    public func assemble(facts: [FactCard], questions: [QuestionCard]) -> [FeedItem] {
        var items: [FeedItem] = []
        items.reserveCapacity(facts.count + questions.count)

        var factIndex = 0
        var questionIndex = 0
        var shouldUseFact = true

        while factIndex < facts.count || questionIndex < questions.count {
            if shouldUseFact, factIndex < facts.count {
                items.append(.fact(facts[factIndex]))
                factIndex += 1
            } else if !shouldUseFact, questionIndex < questions.count {
                items.append(.question(questions[questionIndex]))
                questionIndex += 1
            } else if factIndex < facts.count {
                items.append(.fact(facts[factIndex]))
                factIndex += 1
            } else if questionIndex < questions.count {
                items.append(.question(questions[questionIndex]))
                questionIndex += 1
            }

            shouldUseFact.toggle()
        }

        return items
    }
}
