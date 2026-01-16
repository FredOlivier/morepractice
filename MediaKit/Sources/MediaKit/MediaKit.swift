import Foundation
import CoreGraphics

public enum MediaPresentationMode: String, Sendable {
    case fit
    case fill
    case smartCrop
}

public struct MediaAspectInfo: Sendable {
    public let pixelSize: CGSize
    public let aspectRatio: CGFloat

    public init(pixelSize: CGSize) {
        self.pixelSize = pixelSize
        self.aspectRatio = pixelSize.height == 0 ? 0 : (pixelSize.width / pixelSize.height)
    }
}

public struct CropRectNormalized: Sendable, Equatable {
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    public func toPixelRect(in pixelSize: CGSize) -> CGRect {
        CGRect(
            x: x * pixelSize.width,
            y: y * pixelSize.height,
            width: width * pixelSize.width,
            height: height * pixelSize.height
        )
    }
}
