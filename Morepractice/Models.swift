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
