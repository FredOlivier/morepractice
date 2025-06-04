//
//  UploadEditView.swift
//  Morepractice
//
//  Created by Fred Olivier on 12/04/2025.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// We reuse the following enums. (Make sure these match what you use elsewhere.)


enum UploadType {
    case imageSingle, imagePair, videoSingle, videoPair
}

struct UploadEditView: View {
    let uploadType: UploadType  // Upload type (e.g. .imageSingle, .videoPair, etc.)
    let mediaType: MediaType    // Type of media selected (e.g. .image, .video, etc.)

    // Use PhotosPicker (iOS 16+) to select media.
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMediaData: [Data] = []
    
    // Metadata fields
    @State private var category: String = ""
    @State private var descriptionText: String = ""
    @State private var tagsInput: String = "" // Comma-separated tags
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let previewImage = selectedImagePreview(), (mediaType == .image || mediaType == .pairImageUpload) {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else if mediaType == .video || mediaType == .pairVideoUpload {
                    Text("Video selected")
                        .foregroundColor(.gray)
                } else {
                    Text("No media selected")
                        .foregroundColor(.gray)
                }
                
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: (uploadType == .imagePair || uploadType == .videoPair) ? 2 : 1,
                    matching: (mediaType == .image || mediaType == .pairImageUpload) ? .images : .videos,
                    photoLibrary: .shared()
                ) {
                    Text("Select \( (uploadType == .imagePair || uploadType == .videoPair) ? "Pair" : "Single" ) \( (mediaType == .image || mediaType == .pairImageUpload) ? "Image" : "Video" )")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                }
                .onChange(of: selectedItems) { newItems in
                    loadSelectedMedia(from: newItems)
                }
                
                Group {
                    TextField("Category", text: $category)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Description", text: $descriptionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Enter tags (comma separated)", text: $tagsInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button("Upload") {
                    uploadMedia()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Edit Upload")
    }
    
    // MARK: - Helper Functions
    
    private func selectedImagePreview() -> UIImage? {
        if (mediaType == .image || mediaType == .pairImageUpload),
           let data = selectedMediaData.first,
           let img = UIImage(data: data) {
            return img
        }
        return nil
    }
    
    private func loadSelectedMedia(from items: [PhotosPickerItem]) {
        selectedMediaData.removeAll()
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data {
                            selectedMediaData.append(data)
                        }
                    case .failure(let error):
                        print("Error loading media: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func uploadMedia() {
        guard !selectedMediaData.isEmpty else { return }
        let tags = tagsInput.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        UploadManager.shared.uploadMedia(
            uploadType: uploadType,
            mediaType: mediaTypeForUpload(),
            mediaData: selectedMediaData,
            category: category,
            description: descriptionText,
            tags: tags
        ) { success, error in
            if success {
                print("Upload successful!")
                dismiss()
            } else {
                print("Upload failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func mediaTypeForUpload() -> MediaType {
        // For this view, if the mediaType is .image or .pairImageUpload return .image,
        // and if it is .video or .pairVideoUpload return .video.
        switch mediaType {
        case .image, .pairImageUpload:
            return .image
        case .video, .pairVideoUpload:
            return .video
        case .pair:
            return .pair
        case .singleImage:
            return .singleImage
        case .singleVideo:
            return .singleVideo
        }
    }
}

struct UploadEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            // For preview purposes, assume single image upload.
            UploadEditView(uploadType: .imageSingle, mediaType: .image)
        }
    }
}
