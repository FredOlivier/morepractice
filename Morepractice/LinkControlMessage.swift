//
//  LinkControlMessage.swift
//  Morepractice
//
//  Created by Fred Olivier on 24/04/2025.
//


import Foundation

/// Codable wrapper for signalling *control* (non-SDP / non-ICE) messages
struct LinkControlMessage: Codable {
    let cmd: String              // extend, extendAck, extendDecline …
    let payload: [String:String]?
}
