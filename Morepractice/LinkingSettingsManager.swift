//
//  LinkingSettingsManager.swift
//  Morepractice
//
//  Created by Fred Olivier on 11/04/2025.
//

import Foundation
import SwiftUI

enum EligibilityModeOption: String, CaseIterable, Identifiable {
    case basic, tags
    var id: String { rawValue }
}

class LinkingSettingsManager: ObservableObject {
    /// How often to auto-initiate links.
    @Published var linkInitiationInterval: Double {
        didSet { UserDefaults.standard.set(linkInitiationInterval, forKey: "linkInitiationInterval") }
    }

    @Published var extensionDuration: Int = 30
    @Published var currentSimilarity: Double = 0
    @Published var totalExtendedSeconds: Int = 0

    enum CooldownMode: String, CaseIterable, Identifiable {
        case none, time, interaction
        var id: String { rawValue }
    }
    @Published var cooldownMode: CooldownMode {
        didSet { UserDefaults.standard.set(cooldownMode.rawValue, forKey: "cooldownMode") }
    }

    /// If `.time`, wait this many seconds before rematching.
    @Published var cooldownTime: TimeInterval {
        didSet { UserDefaults.standard.set(cooldownTime, forKey: "cooldownTime") }
    }

    /// If `.interaction`, require this many *other* links.
    @Published var cooldownInteractions: Int {
        didSet { UserDefaults.standard.set(cooldownInteractions, forKey: "cooldownInteractions") }
    }

    /// Computed cooldown (seconds) based on mode.
    var cooldownDuration: TimeInterval {
        switch cooldownMode {
        case .none:        return 0
        case .time:        return cooldownTime
        case .interaction: return 0   // enforce elsewhere by count
        }
    }

    @Published var chatDuration: Double {
        didSet { UserDefaults.standard.set(chatDuration, forKey: "chatDuration") }
    }
    @Published var selectedEligibilityModes: Set<EligibilityModeOption> = [.basic]
    enum SocialPool: String, CaseIterable, Identifiable {
        case everyone, friends, mutualFriends
        var id:String{rawValue}
    }
    @Published var socialPool: SocialPool = .everyone

    init() {
        self.linkInitiationInterval = UserDefaults.standard
            .double(forKey: "linkInitiationInterval") != 0
            ? UserDefaults.standard.double(forKey: "linkInitiationInterval")
            : 15.0

        self.chatDuration = UserDefaults.standard
            .double(forKey: "chatDuration") != 0
            ? UserDefaults.standard.double(forKey: "chatDuration")
            : 15.0

        let modeRaw = UserDefaults.standard.string(forKey: "cooldownMode") ?? CooldownMode.time.rawValue
        self.cooldownMode = CooldownMode(rawValue: modeRaw) ?? .time

        self.cooldownTime = UserDefaults.standard
            .double(forKey: "cooldownTime") != 0
            ? UserDefaults.standard.double(forKey: "cooldownTime")
            : 60.0

        self.cooldownInteractions = UserDefaults.standard
            .integer(forKey: "cooldownInteractions") != 0
            ? UserDefaults.standard.integer(forKey: "cooldownInteractions")
            : 1
    }
}
