// ChatViewWrapper.swift

import SwiftUI

struct ChatViewWrapper: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager

    var body: some View {
        NavigationStack {
            ChatView(viewModel: ChatViewModel(chatId: "Chat_12345", authViewModel: authViewModel))
                .environmentObject(authViewModel)
                .environmentObject(scoreManager)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true) // Hide the default back button
        }
    }
}

struct ChatViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        ChatViewWrapper()
            .environmentObject(AuthViewModel())
            .environmentObject(ScoreManager(authViewModel: AuthViewModel()))
    }
}
