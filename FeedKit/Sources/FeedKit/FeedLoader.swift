import Foundation

public enum FeedLoaderError: Error, Equatable {
    case missingResource(String)
}

public struct FeedLoader: Sendable {
    public init() {}

    public func loadFixture(named name: String, bundle: Bundle) throws -> FeedFixture {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw FeedLoaderError.missingResource(name)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FeedFixture.self, from: data)
    }
}
