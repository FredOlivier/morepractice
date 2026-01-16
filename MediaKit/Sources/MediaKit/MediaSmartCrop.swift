#if canImport(UIKit)
import CoreGraphics
import Vision
import UIKit

public enum MediaSmartCrop {
    public static func faceBoundingBoxNormalizedTopLeft(
        for cgImage: CGImage
    ) -> CropRectNormalized? {
        detectFaceBoundingBoxNormalizedTopLeft(for: cgImage)
    }

    public static func faceCropRectNormalized(
        for cgImage: CGImage,
        targetAspectRatio: CGFloat
    ) -> CropRectNormalized? {
        guard let faceRect = detectFaceBoundingBoxNormalizedTopLeft(for: cgImage) else {
            return nil
        }

        let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
        return MediaCropMath.cropRectNormalized(
            focusRectNormalized: faceRect,
            sourceSize: sourceSize,
            targetAspectRatio: targetAspectRatio
        )
    }

    public static func croppedImage(
        from image: UIImage,
        cropRectNormalized: CropRectNormalized
    ) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let rect = cropRectNormalized.toPixelRect(in: pixelSize).integral
        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }

    private static func detectFaceBoundingBoxNormalizedTopLeft(
        for cgImage: CGImage
    ) -> CropRectNormalized? {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first as? VNFaceObservation else {
            return nil
        }

        let boundingBox = observation.boundingBox
        return CropRectNormalized(
            x: boundingBox.origin.x,
            y: 1 - (boundingBox.origin.y + boundingBox.size.height),
            width: boundingBox.size.width,
            height: boundingBox.size.height
        )
    }
}
#endif
