//
//  VideoLinkState.swift
//  Morepractice
//
//  Created by Fred Olivier on 24/04/2025.
//


import Foundation
import Combine

/// Holds remaining seconds + extend logic so LinkManager can mutate without
/// tight coupling to the SwiftUI view.
final class VideoLinkState: ObservableObject {
    static let shared = VideoLinkState()
    @Published var remainingSeconds: Int = 0
    private init(){}

    func start(seconds: Int) { remainingSeconds = seconds }
    func extend(by sec:Int)  { remainingSeconds += sec }
}
