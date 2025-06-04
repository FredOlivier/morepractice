//
//  UploadDetailView.swift
//  Morepractice
//
//  Created by Fred Olivier on [date].
//

import SwiftUI
import AVKit
import FirebaseFirestore
import FirebaseStorage
import Firebase



struct UploadDetailView: View {
    let uploadType: MediaUploadMode

    // For images or video URLs (depending on upload mode)
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideoURLs: [URL] = []
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Metadata fields
    @State private var userDescription: String = ""
    @State private var userCategory: String = ""
    @State private var userTags: [String] = Array(repeating: "", count: 5)
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var uploadManager = UploadManager()
    @State private var isUploading = false
    
    // Controls presentation of the media picker sheet.
    @State private var showPicker: Bool = false

    // Custom initializer to inject selected media.
    init(uploadType: MediaUploadMode, images: [UIImage] = [], videoURLs: [URL] = []) {
        self.uploadType = uploadType
        _selectedImages = State(initialValue: images)
        _selectedVideoURLs = State(initialValue: videoURLs)
    }
    
    // MARK: - Computed Properties
    
    // Convert the current upload mode to the UploadManager's UploadType.
    private var convertedUploadType: UploadType {
        switch uploadType {
        case .imageSingle:
            return .imageSingle
        case .imagePair:
            return .imagePair
        case .videoSingle:
            return .videoSingle
        case .videoPair:
            return .videoPair
        }
    }
    
    // Convert upload mode to a MediaType (to determine which Firestore subcollection to use).
    private func mediaTypeForUpload() -> MediaType {
        switch uploadType {
        case .imageSingle:
            return .singleImage
        case .imagePair:
            return .pairImageUpload
        case .videoSingle:
            return .singleVideo
        case .videoPair:
            return .pairVideoUpload
        }
    }
    
    // Prepare an array of Data from selected media.
    private var mediaData: [Data] {
        switch uploadType {
        case .imageSingle, .imagePair:
            return selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        case .videoSingle, .videoPair:
            return selectedVideoURLs.compactMap { url in
                return try? Data(contentsOf: url)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    // MEDIA PREVIEW:
                    if uploadType == .imageSingle || uploadType == .imagePair {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        }
                    } else if uploadType == .videoSingle || uploadType == .videoPair {
                        ForEach(selectedVideoURLs, id: \.self) { url in
                            VideoPlayerView(videoURL: url)
                                .frame(height: 200)
                        }
                    }
                    
                    // "Choose More Media" button.
                    Button("Choose More Media") {
                        showPicker = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // Metadata entry fields:
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Category", text: $userCategory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Description", text: $userDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        ForEach(0..<5, id: \.self) { index in
                            TextField("Tag \(index + 1)", text: $userTags[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if isUploading {
                        ProgressView("Uploading...")
                            .padding()
                    }
                    
                    // Action buttons: Cancel and Upload.
                    HStack(spacing: 15) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        
                        Button("Upload") {
                            uploadMedia()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
            }
            .navigationTitle("Upload Detail")
            .navigationBarHidden(false)
            // Present the picker sheet when needed.
            .sheet(isPresented: $showPicker) {
                // For simplicity, here we assume image picking. If uploadType indicates video,
                // you would present a similar VideoPickerView.
                UploadPickerView(mode: self.uploadType) { newImages in
                    // Append the new images to the existing selection.
                    self.selectedImages.append(contentsOf: newImages)
                }
            }
        }
    }
    
    // MARK: - Upload Media Function
    private func uploadMedia() {
        // Validate the media selection based on the upload mode.
        let validSelection: Bool = {
            switch uploadType {
            case .imageSingle:
                return !selectedImages.isEmpty
            case .imagePair:
                return selectedImages.count == 2
            case .videoSingle:
                return !selectedVideoURLs.isEmpty
            case .videoPair:
                return selectedVideoURLs.count == 2
            }
        }()
        
        guard validSelection else {
            print("No valid media selected")
            return
        }
        
        isUploading = true
        
        uploadManager.uploadMedia(
            uploadType: convertedUploadType,
            mediaType: mediaTypeForUpload(),
            mediaData: mediaData,
            category: userCategory,
            description: userDescription,
            tags: userTags.filter { !$0.isEmpty }
        ) { success, error in
            isUploading = false
            if success {
                print("Upload successful.")
                dismiss()
            } else {
                print("Upload failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .onAppear {
                AVPlayer(url: videoURL).play()
            }
    }
}

struct UploadDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UploadDetailView(uploadType: .imageSingle, images: [UIImage(named: "sample") ?? UIImage()])
                .environmentObject(AuthViewModel())
                .environmentObject(SettingsManager())
                .environmentObject(AppViewModel())
        }
    }
}
