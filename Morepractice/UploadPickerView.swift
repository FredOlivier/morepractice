//
//  UploadPickerView.swift
//  Morepractice
//
//  Created by Fred Olivier on [date].
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - UIImage Transferable
// This extension allows UIImage to be loaded with the loadTransferable API.
extension UIImage: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .image) { image in
            guard let data = image.jpegData(compressionQuality: 1.0) else {
                throw NSError(domain: "UIImageTransferError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
            }
            return data
        } importing: { data in
            guard let image = UIImage(data: data) else {
                throw NSError(domain: "UIImageTransferError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
            }
            return image
        }
    }
}

// MARK: - MediaUploadMode Definition
// (Adjust these cases as needed.)
enum MediaUploadMode {
    case imageSingle, imagePair, videoSingle, videoPair

    var selectionLimit: Int {
        switch self {
        case .imageSingle, .videoSingle: return 1
        case .imagePair, .videoPair: return 2
        }
    }
    
    var filter: PHPickerFilter? {
        switch self {
        case .imageSingle, .imagePair: return .images
        case .videoSingle, .videoPair: return .videos
        }
    }
}

// MARK: - UploadPickerView
struct UploadPickerView: UIViewControllerRepresentable {
    /// The mode determines the selection limit and filter.
    var mode: MediaUploadMode
    /// Closure called with the selected images (or videos, if you extend it) when picking is complete.
    var onImagesPicked: ([UIImage]) -> Void

    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = mode.selectionLimit
        config.filter = mode.filter
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No update needed.
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: UploadPickerView

        init(_ parent: UploadPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker.
            picker.dismiss(animated: true)
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    if #available(iOS 16.0, *) {
                        result.itemProvider.loadTransferable(type: UIImage.self) { (result: Result<UIImage, Error>) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let image):
                                    images.append(image)
                                case .failure(let error):
                                    print("Error loading image: \(error.localizedDescription)")
                                }
                                group.leave()
                            }
                        }
                    } else {
                        // For iOS versions earlier than 16 (fallback)
                        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                            DispatchQueue.main.async {
                                if let image = object as? UIImage {
                                    images.append(image)
                                } else {
                                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                                }
                                group.leave()
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onImagesPicked(images)
                self.parent.dismiss()
            }
        }
    }
}

struct UploadPickerView_Previews: PreviewProvider {
    static var previews: some View {
        UploadPickerView(mode: .imageSingle) { images in
            print("Picked \(images.count) images")
        }
    }
}
