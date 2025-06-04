//
//  MediaProtocls.swift
//  Morepractice
//
//  Created by Fred Olivier on 10/01/2025.
//

import Foundation

import Foundation

enum MediaType {
    // For scoring (if still used)
    case image
    case video
    case pair       // used in pair scoring view (unchanged)

    // For uploads (new cases for clear upload use)
    case singleImage
    case pairImageUpload
    case singleVideo
    case pairVideoUpload
}



protocol MediaProtocol: Identifiable {
    var id: String { get }
    var category: String { get }
    var mediaType: MediaType { get }
}

// Example subtypes
struct ImageMedia: MediaProtocol {
    let id: String
    let category: String
    let mediaType: MediaType = .image
    
    let imageURL: String
}

struct VideoMedia: MediaProtocol {
    let id: String
    let category: String
    let mediaType: MediaType = .video
    
    let videoURL: String
}
