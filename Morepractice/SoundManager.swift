//
//  SoundManager.swift
//  Morepractice
//
//  Created by Fred Olivier on 09/01/2025.
//

import Foundation
// SoundManager.swift

import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    /// Plays the specified sound if sound is enabled.
    /// - Parameter soundName: The name of the sound file (excluding extension).
    func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file \(soundName).mp3 not found.")
            return
        }
        
        do {
            // Initialize the audio player with the sound file.
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing sound \(soundName): \(error.localizedDescription)")
        }
    }
}
