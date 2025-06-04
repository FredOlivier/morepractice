import SwiftUI
import Combine
import FirebaseAuth
import WebRTC
import UIKit

class AppViewModel: ObservableObject, LinkManagerDelegate {
    // MARK: - Published State
    @Published var authViewModel: AuthViewModel
    @Published var scoreManager: ScoreManager
    @Published var mediaManager: MediaManager
    @Published var settingsManager: SettingsManager
    @Published var linkingSettingsManager: LinkingSettingsManager

    @Published var messages: [String] = []
    @Published var isChatChannelOpen: Bool = false
    @Published var linkingMode: Bool = false
    @Published var showRatingView: Bool = false
    @Published var ratingSnapshot: UIImage?
    @Published var linkLength: TimeInterval = 0
    @Published var lastSessionId: String?
    @Published var linkOtherUser: String?
    @Published var linkStartTime: Date?
    @Published var debugLogs: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let medMgr = MediaManager(scoreManager: scoreMgr)
        let settMgr = SettingsManager()
        let linkSetMgr = LinkingSettingsManager()
        
        self.authViewModel = authVM
        self.scoreManager = scoreMgr
        self.mediaManager = medMgr
        self.settingsManager = settMgr
        self.linkingSettingsManager = linkSetMgr
        
        // LinkManager wiring
        LinkManager.shared.setAuthViewModel(authVM)
        LinkManager.shared.setAppViewModel(self)
        LinkManager.shared.delegate = self
        
        
        
    }

    // MARK: - Logging
    func logDebug(_ text: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(ts)] \(text)"
        print(entry)
        DispatchQueue.main.async {
            self.debugLogs.insert(entry, at: 0)
            if self.debugLogs.count > 1000 { self.debugLogs.removeLast() }
        }
    }

    // MARK: - LinkManagerDelegate
    func didInitiateLink(sessionId: String) {
        logDebug("didInitiateLink for sessionId=\(sessionId)")
        DispatchQueue.main.async {
            self.lastSessionId = sessionId
            self.linkStartTime = Date()
            self.linkOtherUser = LinkManager.shared.targetUsername
            self.isChatChannelOpen = true
        }
    }

    func didTerminateLink() {
        logDebug("didTerminateLink triggered")
        DispatchQueue.main.async {
            if let start = self.linkStartTime {
                self.linkLength = Date().timeIntervalSince(start)
            }
            // snapshot the key window
            if let win = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                self.ratingSnapshot = win.rootViewController?.view.snapshot()
                
            }
            
            
            self.isChatChannelOpen = false
            self.showRatingView = true
        }
    }

    func didReceiveMessage(_ message: String) {
        logDebug("didReceiveMessage(\(message))")
        DispatchQueue.main.async { self.messages.append(message) }
    }

    // MARK: - Sending Chat
    func sendChatMessage(_ message: String) {
        logDebug("sendChatMessage(\(message)), channel open? \(isChatChannelOpen)")
        guard let ch = LinkManager.shared.rtcDataChannel else {
            print("No rtcDataChannel"); return
        }
        guard ch.readyState == .open else {
            print("Channel not open"); return
        }
        guard let data = message.data(using: .utf8) else { return }
        let ok = ch.sendData(RTCDataBuffer(data: data, isBinary: false))
        if ok {
            DispatchQueue.main.async { self.messages.append("You: \(message)") }
        }
    }
}

// UIView snapshot helper
extension UIView {
    func snapshot() -> UIImage {
        UIGraphicsImageRenderer(bounds: bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
