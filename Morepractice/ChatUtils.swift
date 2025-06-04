//
//  ChatUtils.swift
//  Morepractice
//
//  Created by Fred Olivier on 24/12/2024.
//

import Foundation
// ChatUtils.swift

import Foundation

struct ChatUtils {
    /// Generates a deterministic chatId by sorting usernames alphabetically and concatenating them with an underscore
    static func generateChatId(userA: String, userB: String) -> String {
        let sortedUsers = [userA, userB].sorted()
        return "\(sortedUsers[0])_\(sortedUsers[1])"
    }
}
