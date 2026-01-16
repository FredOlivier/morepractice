import XCTest
@testable import MediaKit

final class MediaKitTests: XCTestCase {
    func testAspectRatio() {
        let info = MediaAspectInfo(pixelSize: .init(width: 200, height: 100))
        XCTAssertEqual(info.aspectRatio, 2.0, accuracy: 0.0001)
    }
}
