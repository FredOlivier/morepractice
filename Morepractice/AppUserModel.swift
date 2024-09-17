//
//  UserModel.swift
//  Morepractice
//
//  Created by Fred Olivier on 14/12/2024.
//

import Foundation
// User.swift


// Define the AppUser struct with all necessary properties
struct AppUser: Identifiable, Hashable {
    let id: String            // Using username as id
    let name: String
    let email: String
    let isOnline: Bool
    let uid: String           // Firebase UID
    let similarityScore: Double
}
