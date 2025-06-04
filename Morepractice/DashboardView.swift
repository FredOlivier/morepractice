// DashboardView.swift

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var imageManager: ImageManager

    // State variables to control modal presentations
    @State private var showChatView: Bool = false
    @State private var showChooseView: Bool = false

    // State variable to toggle Similar Users section
    @State private var showSimilarUsers: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Home")
                .font(.largeTitle)
                .padding()

            // Navigation Buttons
            Button(action: {
                showChatView = true
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.white)
                    Text("Chat")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .accessibilityLabel("Chat")
            .accessibilityHint("Open the chat interface")
            .fullScreenCover(isPresented: $showChatView) {
                // Initialize ChatViewModel with a unique chatId
                let chatId = UUID().uuidString  // Replace with your logic for chatId
                let chatVM = ChatViewModel(chatId: chatId, authViewModel: authViewModel)
                
                // Present ChatViewWrapper with the initialized ChatViewModel
                ChatViewWrapper(chatViewModel: chatVM)
                    .environmentObject(authViewModel)
                    .environmentObject(scoreManager)
                    .environmentObject(imageManager)
            }

            Button(action: {
                showChooseView = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.white)
                    Text("Choose")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
            .accessibilityLabel("Choose")
            .accessibilityHint("Choose an image for scoring")
            .fullScreenCover(isPresented: $showChooseView) {
                ImageScoringViewWrapper()
                    .environmentObject(authViewModel)
                    .environmentObject(scoreManager)
                    .environmentObject(imageManager)
            }

            Button(action: {
                withAnimation {
                    showSimilarUsers.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.white)
                    Text("Similar Users")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
            }
            .accessibilityLabel("Similar Users")
            .accessibilityHint("Show users similar to you")

            // Similar Users Section
            if showSimilarUsers {
                SimilarUsersSectionView()
                    .transition(.opacity)
                    .environmentObject(scoreManager)
                    .environmentObject(imageManager)
            }

            Spacer()
        }
        .padding()
    }

    struct UserData: Identifiable {
        let id: UUID
        let username: String
        let email: String
    }

    struct DashboardView_Previews: PreviewProvider {
        static var previews: some View {
            let appVM = AppViewModel()

            DashboardView()
                .environmentObject(appVM.authViewModel)
                .environmentObject(appVM.scoreManager)
                .environmentObject(appVM.imageManager)
        }
    }
}
