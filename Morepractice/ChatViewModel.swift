/*import Foundation
import Combine
import WebRTC

class ChatViewModel: ObservableObject, LinkManagerDelegate {
    @Published var messages: [String] = []
    @Published var newMessage: String = ""
    @Published var isChannelOpen: Bool = false

    // MARK: - LinkManagerDelegate Methods

    /// Called when the link is successfully initiated.
    func didInitiateLink(sessionId: String) {
        print("ChatViewModel: Link initiated for session \(sessionId)")
    }
    
    /// Called when the link is terminated.
    func didTerminateLink() {
        print("ChatViewModel: Link terminated")
        DispatchQueue.main.async {
            self.isChannelOpen = false
        }
    }
    
    /// Called when a new message is received via the RTCDataChannel.
    func didReceiveMessage(_ message: String) {
        print("ChatViewModel: didReceiveMessage called with: '\(message)'")
        DispatchQueue.main.async {
            self.messages.append(message)
            print("ChatViewModel: Message appended. Current messages: \(self.messages)")
        }
    }
    
    // MARK: - Send Message Function

    /// Encodes and sends a chat message over the RTCDataChannel.
    func sendMessage() {
        print("ChatViewModel: Initiating sendMessage with message: '\(newMessage)'")
        
        guard let channel = LinkManager.shared.rtcDataChannel else {
            print("CHAT SEND ERROR: rtcDataChannel is nil. Cannot send message.")
            return
        }
        
        guard channel.readyState == .open else {
            print("CHAT SEND ERROR: rtcDataChannel is not open. Current state: \(channel.readyState.rawValue)")
            return
        }
        
        guard let data = newMessage.data(using: .utf8) else {
            print("CHAT SEND ERROR: Failed to encode message to Data.")
            return
        }
        
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        print("ChatViewModel: Attempting to send message: '\(newMessage)'")
        let success = channel.sendData(buffer)
        print("ChatViewModel: channel.sendData returned: \(success)")
        
        if success {
            DispatchQueue.main.async {
                self.messages.append("You: \(self.newMessage)")
                self.newMessage = ""
            }
        }
    }
    
    /// Called to end the chat session.
    func endChat() {
        print("ChatViewModel: endChat called.")
        // Any additional cleanup logic can be added here.
    }
}
*/
