
//
//  Score.swift
//  Morepractice
//
//  Created by Fred Olivier on 17/09/2024.
//
import Foundation


//
//  Score.swift
//  Morepractice
//
//  Created by Fred Olivier on 17/09/2024.
//

import Foundation

struct Score: Identifiable, Codable, Hashable {
    var id: String // Changed from UUID to String to match Firestore document ID
    var slider1: Double
    var slider2: Double
    var image1: String
    var image2: String
    var image1URL: String
    var image2URL: String
    var relationalScore: Double
    var date: Date
}
