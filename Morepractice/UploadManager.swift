//
//  UploadManager.swift
//  Morepractice
//
//  Created by Fred Olivier on … (updated 2025-04-XX).
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth



class UploadManager: ObservableObject {
    static let shared = UploadManager()

    private let firestore = Firestore.firestore()
    private let storage   = Storage.storage()

    /// Uploads media files to Firebase Storage and then creates
    /// a Firestore document with full metadata, including uploader UID,
    /// an initial empty ratings array, and the generated document ID.
    func uploadMedia(
        uploadType: UploadType,
        mediaType: MediaType,
        mediaData: [Data],
        category: String,
        description: String,
        tags: [String],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            completion(false, NSError(
                domain: "UploadManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey:"User not signed in"]
            ))
            return
        }
        let userId = user.uid

        // 1) Upload each file to Storage
        let storageRef = storage.reference()
            .child("user_upload")
            .child(userId)

        var downloadURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?

        for data in mediaData {
            dispatchGroup.enter()
            let ext = (mediaType == .video || mediaType == .pairVideoUpload) ? "mp4" : "jpg"
            let fileName = "\(UUID().uuidString).\(ext)"
            let fileRef = storageRef.child(fileName)

            fileRef.putData(data, metadata: nil) { _, error in
                if let error = error {
                    uploadError = error
                    dispatchGroup.leave()
                    return
                }
                fileRef.downloadURL { url, error in
                    if let error = error {
                        uploadError = error
                    } else if let url = url {
                        downloadURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        // 2) Once all uploads finish, write Firestore doc
        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                completion(false, error)
                return
            }

            // select subcollection
            let sub: String = {
                switch uploadType {
                case .imageSingle: return "single_upload"
                case .imagePair:   return "pairs"
                case .videoSingle: return "videos"
                case .videoPair:   return "video_pairs"
                }
            }()

            // prepare docRef/documentID
            let userDoc = self.firestore
                .collection("user_upload")
                .document(userId)
                .collection(sub)
            let docRef = userDoc.document()  // auto-ID
            let docID = docRef.documentID

            // build payload
            var payload: [String:Any] = [
                "id":          docID,
                "uploaderUid": userId,
                "mediaURLs":   downloadURLs,
                "category":    category,
                "description": description,
                "tags":        tags,
                "uploadDate":  Timestamp(date: Date()),
                // initialize ratings structure
                "ratingCount": 0,
                "average":     0.0,
                "ratings":     [[String:Any]]()  // array of { scorerUid, score, ts, maybe otherMediaId/URL }
            ]

            // finally write
            docRef.setData(payload) { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}
