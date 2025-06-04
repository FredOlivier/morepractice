//
//  EphemeralChatContainer.swift
//  Morepractice
//
/*
import SwiftUI

struct EphemeralChatContainer: View {
    @ObservedObject var ephemeralChatVM: EphemeralChatViewModel
    
    /// Called when the user manually closes or when the ephemeral chat ends
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ChatView(viewModel: ephemeralChatVM)
                .navigationTitle("AutoChat (\(ephemeralChatVM.user1Name) & \(ephemeralChatVM.user2Name))")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            onDismiss()
                        }
                    }
                }
        }
        .onAppear {
            print("EphemeralChatContainer -> Appear for chatId: \(ephemeralChatVM.chatId)")
        }
        .onDisappear {
            print("EphemeralChatContainer -> Disappear for chatId: \(ephemeralChatVM.chatId)")
        }
    }
}

// MARK: - Preview

struct EphemeralChatContainer_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let medMgr = MediaManager(scoreManager: scoreMgr)
        
        let ephemeralVM = EphemeralChatViewModel(
            chatId: "EphemeralChat123",
            authViewModel: authVM,
            isEphemeral: true,
            expiresAt: Date().addingTimeInterval(30)
        )
        
        EphemeralChatContainer(ephemeralChatVM: ephemeralVM) {
            // Mock onDismiss action
            print("Dismissed Ephemeral Chat")
        }
    }
}
 /**/*/
