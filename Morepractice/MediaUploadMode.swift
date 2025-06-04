import Foundation
import PhotosUI



extension MediaUploadMode {
    /// Returns the Firestore subcollection name where the media should be stored.
    /// - For a single image upload, it returns "single_upload"
    /// - For an image pair upload, it returns "pairs"
    /// - For a single video upload, it returns "videos"
    /// - For a video pair upload, it returns "video_pairs"
    var firestoreSubcollection: String {
        switch self {
        case .imageSingle:
            return "single_upload"
        case .imagePair:
            return "pairs"
        case .videoSingle:
            return "videos"
        case .videoPair:
            return "video_pairs"
        }
    }
}
