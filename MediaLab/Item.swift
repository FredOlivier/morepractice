//
//  Item.swift
//  MediaLab
//
//  Created by Fred Olivier on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
