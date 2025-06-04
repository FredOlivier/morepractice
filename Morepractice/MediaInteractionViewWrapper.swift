//
//  MediaInteractionViewWrapper.swift
//  Morepractice
//
//  Created by Fred Olivier on 10/01/2025.
//

import Foundation
//
//  MediaInteractionViewWrapper.swift
//  Morepractice
//
//  NOTE: Replaces references from "ImageScoringViewWrapper" to "MediaInteractionViewWrapper"
//        and from "image" to "media" in environment objects.
//
import SwiftUI

struct MediaInteractionViewWrapper: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var mediaManager: MediaManager // Replaces old imageManager
    
    var body: some View {
        NavigationStack {
            MediaInteractionView()
                .environmentObject(authViewModel)
                .environmentObject(scoreManager)
                .environmentObject(settingsManager)
                .environmentObject(soundManager)
                .environmentObject(mediaManager)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Media Interaction")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true) // Hide the default back button
        }
    }
}

struct MediaInteractionViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let mediaMgr = MediaManager(scoreManager: scoreMgr)
        let settingsMgr = SettingsManager()
        let soundMgr = SoundManager.shared
        
        MediaInteractionViewWrapper()
            .environmentObject(authVM)
            .environmentObject(scoreMgr)
            .environmentObject(mediaMgr)
            .environmentObject(settingsMgr)
            .environmentObject(soundMgr)
    }
}
