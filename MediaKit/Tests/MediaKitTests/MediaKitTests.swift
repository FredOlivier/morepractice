import XCTest
import CoreGraphics
@testable import MediaKit

final class MediaKitTests: XCTestCase {
    func testAspectRatio() {
        let info = MediaAspectInfo(pixelSize: .init(width: 200, height: 100))
        XCTAssertEqual(info.aspectRatio, 2.0, accuracy: 0.0001)
    }

    func testCropRectNormalizedSquareFromWideSource() {
        let focus = CropRectNormalized(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let result = MediaCropMath.cropRectNormalized(
            focusRectNormalized: focus,
            sourceSize: CGSize(width: 200, height: 100),
            targetAspectRatio: 1
        )

        XCTAssertEqual(result.x, 0.25, accuracy: 0.0001)
        XCTAssertEqual(result.y, 0.0, accuracy: 0.0001)
        XCTAssertEqual(result.width, 0.5, accuracy: 0.0001)
        XCTAssertEqual(result.height, 1.0, accuracy: 0.0001)
    }

    func testCropRectNormalizedWideTargetAspect() {
        let focus = CropRectNormalized(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
        let result = MediaCropMath.cropRectNormalized(
            focusRectNormalized: focus,
            sourceSize: CGSize(width: 100, height: 100),
            targetAspectRatio: 2
        )

        XCTAssertEqual(result.x, 0.3, accuracy: 0.0001)
        XCTAssertEqual(result.y, 0.4, accuracy: 0.0001)
        XCTAssertEqual(result.width, 0.4, accuracy: 0.0001)
        XCTAssertEqual(result.height, 0.2, accuracy: 0.0001)
    }

    func testPresentationRecipeClamp() {
        let recipe = MediaPresentationRecipe(
            mode: .fill,
            zoom: 10,
            focalPoint: CGPoint(x: -0.2, y: 1.4),
            fullBleed: true
        )
        let clamped = MediaPresentationMath.clamped(recipe)

        XCTAssertEqual(clamped.zoom, MediaPresentationMath.zoomRange.upperBound, accuracy: 0.0001)
        XCTAssertEqual(clamped.focalPoint.x, 0, accuracy: 0.0001)
        XCTAssertEqual(clamped.focalPoint.y, 1, accuracy: 0.0001)
    }

    func testPresentationOffsetClampsToBounds() {
        let container = CGSize(width: 200, height: 200)
        let scaled = CGSize(width: 400, height: 400)
        let offset = MediaPresentationMath.offset(
            containerSize: container,
            scaledContentSize: scaled,
            focalPoint: CGPoint(x: 0, y: 0)
        )

        XCTAssertEqual(offset.width, 0, accuracy: 0.0001)
        XCTAssertEqual(offset.height, 0, accuracy: 0.0001)
    }
}
