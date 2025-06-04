/*import UIKit
 import WebRTC
 
 class TemporaryChatViewController: UIViewController {
 
 @IBOutlet weak var chatTextView: UITextView!
 @IBOutlet weak var messageTextField: UITextField!
 @IBOutlet weak var sendButton: UIButton!
 
 override func viewDidLoad() {
 super.viewDidLoad()
 chatTextView.text = ""
 
 // Start a 30-second timer to end the chat session.
 Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(endChat), userInfo: nil, repeats: false)
 }
 
 @IBAction func sendButtonTapped(_ sender: UIButton) {
 // First, dismiss the keyboard so the text input session ends gracefully.
 messageTextField.resignFirstResponder()
 
 guard let message = messageTextField.text, !message.isEmpty else { return }
 
 // Send message via RTCDataChannel using sendData(_:)
 if let dataChannel = LinkManager.shared.rtcDataChannel {
 let buffer = RTCDataBuffer(data: message.data(using: .utf8)!, isBinary: false)
 let success = dataChannel.sendData(buffer)
 print("Attempted to send message: '\(message)' with success: \(success)")
 
 // Append outgoing message to chat view.
 appendMessage(text: "You: \(message)")
 } else {
 print("Data channel is not available.")
 }
 
 // Clear the text field.
 messageTextField.text = ""
 }
 
 func appendMessage(text: String) {
 DispatchQueue.main.async {
 self.chatTextView.text.append("\n\(text)")
 let range = NSRange(location: self.chatTextView.text.count - 1, length: 1)
 self.chatTextView.scrollRangeToVisible(range)
 }
 }
 
 @objc func endChat() {
 // Notify LinkManager to terminate the link.
 LinkManager.shared.terminateCurrentLink()
 
 // Dismiss the TemporaryChatViewController.
 self.dismiss(animated: true, completion: nil)
 }
 }
 */
