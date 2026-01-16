import CoreGraphics

public struct MediaPresentationRecipe: Sendable, Equatable {
    public var version: Int
    public var mode: MediaPresentationMode
    public var zoom: CGFloat
    public var focalPoint: CGPoint
    public var fullBleed: Bool
    public var calibrationPreset: CalibrationPreset?

    public init(
        version: Int = 1,
        mode: MediaPresentationMode,
        zoom: CGFloat,
        focalPoint: CGPoint,
        fullBleed: Bool,
        calibrationPreset: CalibrationPreset? = nil
    ) {
        self.version = version
        self.mode = mode
        self.zoom = zoom
        self.focalPoint = focalPoint
        self.fullBleed = fullBleed
        self.calibrationPreset = calibrationPreset
    }
}

public enum CalibrationPreset: String, Codable, CaseIterable, Sendable {
    case portrait
    case landscape
}

public enum MediaPresentationMath {
    public static let zoomRange: ClosedRange<CGFloat> = 0.5...3.0

    public static func clamped(_ recipe: MediaPresentationRecipe) -> MediaPresentationRecipe {
        let clampedZoom = min(max(recipe.zoom, zoomRange.lowerBound), zoomRange.upperBound)
        let clampedFocal = CGPoint(
            x: min(max(recipe.focalPoint.x, 0), 1),
            y: min(max(recipe.focalPoint.y, 0), 1)
        )
        return MediaPresentationRecipe(
            version: recipe.version,
            mode: recipe.mode,
            zoom: clampedZoom,
            focalPoint: clampedFocal,
            fullBleed: recipe.fullBleed,
            calibrationPreset: recipe.calibrationPreset
        )
    }

    public static func scaledSize(
        contentSize: CGSize,
        containerSize: CGSize,
        mode: MediaPresentationMode,
        zoom: CGFloat
    ) -> CGSize {
        guard contentSize.width > 0, contentSize.height > 0 else {
            return .zero
        }

        let scaleX = containerSize.width / contentSize.width
        let scaleY = containerSize.height / contentSize.height
        let baseScale = (mode == .fill) ? max(scaleX, scaleY) : min(scaleX, scaleY)
        let scale = baseScale * zoom
        return CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
    }

    public static func offset(
        containerSize: CGSize,
        scaledContentSize: CGSize,
        focalPoint: CGPoint
    ) -> CGSize {
        guard scaledContentSize.width >= containerSize.width,
              scaledContentSize.height >= containerSize.height else {
            return .zero
        }

        let target = CGPoint(
            x: scaledContentSize.width * focalPoint.x,
            y: scaledContentSize.height * focalPoint.y
        )
        var offset = CGPoint(
            x: containerSize.width / 2 - target.x,
            y: containerSize.height / 2 - target.y
        )

        let minX = containerSize.width - scaledContentSize.width
        let minY = containerSize.height - scaledContentSize.height
        offset.x = min(0, max(minX, offset.x))
        offset.y = min(0, max(minY, offset.y))
        return CGSize(width: offset.x, height: offset.y)
    }
}
