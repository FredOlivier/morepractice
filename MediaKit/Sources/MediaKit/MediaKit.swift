import Foundation
import CoreGraphics

public enum MediaPresentationMode: String, Sendable {
    case fit
    case fill
}

public struct MediaAspectInfo: Sendable {
    public let pixelSize: CGSize
    public let aspectRatio: CGFloat

    public init(pixelSize: CGSize) {
        self.pixelSize = pixelSize
        self.aspectRatio = pixelSize.height == 0 ? 0 : (pixelSize.width / pixelSize.height)
    }
}
