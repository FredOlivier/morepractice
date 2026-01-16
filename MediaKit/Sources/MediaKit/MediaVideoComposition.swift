#if canImport(UIKit)
import AVFoundation
import CoreGraphics

public enum MediaVideoCompositionBuilder {
    public static func smartCropComposition(
        asset: AVAsset,
        targetAspectRatio: CGFloat
    ) -> AVVideoComposition? {
        guard let track = asset.tracks(withMediaType: .video).first else {
            return nil
        }

        let orientedSize = orientedDisplaySize(for: track)
        guard orientedSize.width > 0, orientedSize.height > 0 else {
            return nil
        }

        guard let focusRect = faceRectNormalizedFromVideo(asset: asset) else {
            return nil
        }

        let cropRectNormalized = MediaCropMath.cropRectNormalized(
            focusRectNormalized: focusRect,
            sourceSize: orientedSize,
            targetAspectRatio: targetAspectRatio
        )

        let cropRect = cropRectNormalized.toPixelRect(in: orientedSize).integral
        // TODO: If this preview-only approach is unreliable, replace with a more robust smart-crop pipeline.
        let composition = AVMutableVideoComposition(propertiesOf: asset)

        guard
            let instruction = composition.instructions.first as? AVMutableVideoCompositionInstruction,
            let layerInstruction = instruction.layerInstructions.first as? AVMutableVideoCompositionLayerInstruction
        else {
            return nil
        }

        composition.renderSize = cropRect.size
        layerInstruction.setCropRectangle(cropRect, at: .zero)
        instruction.layerInstructions = [layerInstruction]

        return composition
    }

    private static func orientedDisplaySize(for track: AVAssetTrack) -> CGSize {
        let transformed = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(transformed.width), height: abs(transformed.height))
    }

    private static func faceRectNormalizedFromVideo(asset: AVAsset) -> CropRectNormalized? {
        let time = representativeTime(for: asset)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            return MediaSmartCrop.faceBoundingBoxNormalizedTopLeft(for: cgImage)
        } catch {
            return nil
        }
    }

    private static func representativeTime(for asset: AVAsset) -> CMTime {
        let duration = asset.duration
        guard duration.isNumeric, duration.seconds > 0 else {
            return .zero
        }
        let seconds = min(0.5, duration.seconds * 0.1)
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
}
#endif
