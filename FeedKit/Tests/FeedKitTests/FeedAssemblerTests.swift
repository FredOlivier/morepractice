import Testing
@testable import FeedKit

@Test func loadFixtureAndAssemble() throws {
    let fixture = try FeedLoader().loadFixture(named: "sample_feed", bundle: .module)

    #expect(fixture.topic.id == "topic_1")
    #expect(fixture.facts.count == 2)
    #expect(fixture.questions.count == 2)

    #expect(fixture.facts[0].mediaId == "media_1")
    #expect(fixture.facts[0].provenance == nil)
    #expect(fixture.facts[1].mediaId == nil)
    #expect(fixture.facts[1].provenance == "NASA")

    #expect(fixture.questions[0].choices == ["1", "2", "3"])
    #expect(fixture.questions[1].choices == nil)
    #expect(fixture.questions[1].explanation == nil)

    let assembler = FeedAssembler()
    let items = assembler.assemble(facts: fixture.facts, questions: fixture.questions)

    #expect(items.count == 4)
    #expect(itemIds(items) == ["fact_1", "q_1", "fact_2", "q_2"])

    let secondPass = assembler.assemble(facts: fixture.facts, questions: fixture.questions)
    #expect(items == secondPass)
}

private func itemIds(_ items: [FeedItem]) -> [String] {
    items.map { item in
        switch item {
        case .fact(let fact):
            return fact.id
        case .question(let question):
            return question.id
        }
    }
}
