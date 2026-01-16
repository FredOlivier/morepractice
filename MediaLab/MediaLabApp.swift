//
//  MediaLabApp.swift
//  MediaLab
//
import SwiftUI
import FirebaseCore

@main
struct MediaLabApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
