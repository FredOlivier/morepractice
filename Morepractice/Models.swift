//
//  Models.swift
//  Morepractice
//
//  Created by Fred Olivier on 20/09/2024.
//

import Foundation

// Define the Photo struct globally
struct Photo: Identifiable, Codable, Hashable {
    var id: String
    var category: String
    var url: String
}


/// Extra info if the media came from a user‑upload queue
struct UploadMeta: Codable {
    let uploaderUid: String        // owner of the upload
    let uploadPath: String         // full firestore path to doc e.g. "user_upload/abc123/single_upload/xyz"
    let uploadType: String         // "single_upload" | "pairs"
}


struct MediaItem: Identifiable {
    let id: String
    let mediaKind: MediaKind
    let category: String?
    let url: String
    let uploaderUid: String?     // nil if catalogue media
    let uploadDocPath: String?   // path into user_upload/* if applicable


    // -------- NEW --------
    var uploadMeta: UploadMeta?    // nil ⇒ normal system media
    var isUserUpload: Bool { uploadMeta != nil }
}
