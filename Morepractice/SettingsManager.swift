//
//  SettingsManager.swift
//  Morepractice
//
//  Created by Fred Olivier on 09/01/2025.
//

import Combine
import SwiftUI

class SettingsManager: ObservableObject {
    // MARK: - Published Properties

    /// Enables or disables haptic feedback.
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    /// Controls the intensity of haptic feedback.
    @Published var hapticStrength: Double {
        didSet {
            UserDefaults.standard.set(hapticStrength, forKey: "hapticStrength")
        }
    }
    
    /// Enables or disables haptic feedback on the Next button.
    @Published var hapticOnNextButton: Bool {
        didSet {
            UserDefaults.standard.set(hapticOnNextButton, forKey: "hapticOnNextButton")
        }
    }
    
    /// Enables or disables sound effects.
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    /// Controls the linking mode preference.
    @Published var linkingMode: Bool {
        didSet {
            UserDefaults.standard.set(linkingMode, forKey: "linkingMode")
        }
    }

    /// NEW: Animate dashboard circle borders (rainbow center, color-family on outers)
    @Published var animatedBordersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(animatedBordersEnabled, forKey: "animatedBordersEnabled")
        }
    }
    
    // MARK: - Initialization
    init() {
        // Load each property from UserDefaults, or use the default if not set.
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
        self.hapticStrength = UserDefaults.standard.object(forKey: "hapticStrength") as? Double ?? 1.0
        self.hapticOnNextButton = UserDefaults.standard.object(forKey: "hapticOnNextButton") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.linkingMode = UserDefaults.standard.object(forKey: "linkingMode") as? Bool ?? false
        self.animatedBordersEnabled = UserDefaults.standard.object(forKey: "animatedBordersEnabled") as? Bool ?? true
    }
}
