import CoreGraphics

public enum MediaCropMath {
    public static func cropRectNormalized(
        focusRectNormalized: CropRectNormalized,
        sourceSize: CGSize,
        targetAspectRatio: CGFloat,
        paddingFactor: CGFloat = 1.0
    ) -> CropRectNormalized {
        guard sourceSize.width > 0, sourceSize.height > 0, targetAspectRatio > 0 else {
            return CropRectNormalized(x: 0, y: 0, width: 1, height: 1)
        }

        let focusRect = focusRectNormalized.toPixelRect(in: sourceSize)
        let paddedWidth = max(1, focusRect.width * paddingFactor)
        let paddedHeight = max(1, focusRect.height * paddingFactor)

        var cropWidth = max(paddedWidth, paddedHeight * targetAspectRatio)
        var cropHeight = cropWidth / targetAspectRatio

        if cropHeight < paddedHeight {
            cropHeight = paddedHeight
            cropWidth = cropHeight * targetAspectRatio
        }

        if cropWidth > sourceSize.width {
            cropWidth = sourceSize.width
            cropHeight = cropWidth / targetAspectRatio
        }

        if cropHeight > sourceSize.height {
            cropHeight = sourceSize.height
            cropWidth = cropHeight * targetAspectRatio
        }

        let center = CGPoint(x: focusRect.midX, y: focusRect.midY)
        var originX = center.x - cropWidth / 2
        var originY = center.y - cropHeight / 2

        originX = min(max(0, originX), sourceSize.width - cropWidth)
        originY = min(max(0, originY), sourceSize.height - cropHeight)

        return CropRectNormalized(
            x: originX / sourceSize.width,
            y: originY / sourceSize.height,
            width: cropWidth / sourceSize.width,
            height: cropHeight / sourceSize.height
        )
    }
}
