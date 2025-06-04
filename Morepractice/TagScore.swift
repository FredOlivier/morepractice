//
//  TagScore.swift
//  Morepractice
//
//  Created by Fred Olivier on 23/12/2024.
//
//
//  TagScore.swift
//  Morepractice
//
//  Created by Fred Olivier on 17/01/2025.
//

import Foundation

/// Represents a user's accumulated score for a specific tag.
struct TagScore: Identifiable, Codable {
    /// The tag name (e.g., "animals", "culture", "food").
    var id: String
    var totalScore: Double
    var ratingCount: Int
    var averageScore: Double {
        ratingCount == 0 ? 0 : totalScore / Double(ratingCount)
    }
    
    // Default init
    init(id: String, totalScore: Double = 0, ratingCount: Int = 0) {
        self.id = id
        self.totalScore = totalScore
        self.ratingCount = ratingCount
    }
}
