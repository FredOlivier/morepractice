//
//  ErrorWrapper.swift
//  Morepractice
//
//  Created by Fred Olivier on 26/12/2024.
//

// ErrorWrapper.swift

import Foundation

// MARK: - ErrorWrapper

/// A struct to wrap error messages for presenting alerts.
struct ErrorWrapper: Identifiable {
    var id: String { message }
    let message: String
}
