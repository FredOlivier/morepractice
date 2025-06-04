/*
import SwiftUI

struct ChatViewWrapper: View {
    @ObservedObject var chatViewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            ChatView(viewModel: chatViewModel)
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Exit Button
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // Dismiss the ChatView
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Close Chat")
                        .accessibilityHint("Close the chat and return to Dashboard")
                    }
                }
        }
    }
    
    // Dismiss action
    @Environment(\.dismiss) private var dismiss
}

// MARK: - Preview

struct ChatViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let chatVM = ChatViewModel(chatId: "Chat123", authViewModel: authVM)

        ChatViewWrapper(chatViewModel: chatVM)
            .environmentObject(authVM)
    }
}
 /**/*/
