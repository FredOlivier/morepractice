#if canImport(UIKit)
import UIKit

public enum MediaImageLoader {
    public static func normalizedImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        return normalizedImage(image)
    }

    public static func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up, let cgImage = image.cgImage else {
            return image
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            UIImage(cgImage: cgImage, scale: image.scale, orientation: .up).draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
#endif
