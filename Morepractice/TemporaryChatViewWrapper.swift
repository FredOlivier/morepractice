/*import SwiftUI
import UIKit

struct TemporaryChatViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TemporaryChatViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let temporaryChatVC = storyboard.instantiateViewController(withIdentifier: "TemporaryChatViewController") as? TemporaryChatViewController else {
            fatalError("TemporaryChatViewController not found in Main storyboard. Ensure its Storyboard ID is set to 'TemporaryChatViewController'.")
        }
        return temporaryChatVC
    }
    
    func updateUIViewController(_ uiViewController: TemporaryChatViewController, context: Context) {
        // No dynamic updates needed.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: TemporaryChatViewWrapper
        
        init(_ parent: TemporaryChatViewWrapper) {
            self.parent = parent
        }
    }
}
*/
