// ChatView.swift

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - ChatMessage Model

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
}

// MARK: - ChatViewModel

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var chatId: String {
        didSet {
            loadMessages()
        }
    }
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    let authViewModel: AuthViewModel
    
    private var messagesListener: ListenerRegistration?
    
    init(chatId: String, authViewModel: AuthViewModel) {
        guard !chatId.isEmpty else {
            fatalError("Chat ID cannot be empty.")
        }
        self.chatId = chatId
        self.authViewModel = authViewModel
        observeMessages()
    }
    
    deinit {
        messagesListener?.remove()
    }
    
    private func observeMessages() {
        // Remove previous listener if any
        messagesListener?.remove()
        
        messagesListener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error observing messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let fetchedMessages = documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard let sender = data["sender"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else { return nil }
                    
                    return ChatMessage(id: doc.documentID, sender: sender, content: content, timestamp: timestamp)
                }
                
                DispatchQueue.main.async {
                    self?.messages = fetchedMessages
                }
            }
    }
    
    private func loadMessages() {
        observeMessages()
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let sender = authViewModel.currentUserName ?? "Unknown"
        let messageData: [String: Any] = [
            "sender": sender,
            "content": newMessage,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: messageData) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.newMessage = ""
                }
            }
    }
    
    func updateChatId(to newChatId: String) {
        guard newChatId != self.chatId else { return }
        self.chatId = newChatId
        self.messages = [] // Clear current messages
        observeMessages() // Start observing new chatId's messages
    }
}


// MARK: - ChatView

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    
    @StateObject var viewModel: ChatViewModel
    
    @State private var selectedUser: AppUser?
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            // Menu to choose recipient
            HStack {
                Text("Chatting with:")
                    .font(.headline)
                
                Menu {
                    ForEach(scoreManager.similarUsers) { user in
                        Button(user.name) {
                            selectRecipient(user)
                        }
                    }
                } label: {
                    Text(selectedUser?.name ?? "Select User")
                        .foregroundColor(.blue)
                        .underline()
                }
                
                Spacer()
            }
            .padding()
            
            // Messages list
            ScrollView {
                ForEach(viewModel.messages) { message in
                    HStack {
                        if message.sender == (authViewModel.currentUserName ?? "Unknown") {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            
            // Input field and send button
            HStack {
                TextField("Enter message", text: $viewModel.newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding()
                }
                .disabled(viewModel.newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .onAppear {
            // Default to first user if none selected
            if selectedUser == nil, let firstUser = scoreManager.similarUsers.first {
                selectRecipient(firstUser)
            }
        }
    }
    
    private func selectRecipient(_ user: AppUser) {
        self.selectedUser = user
        guard let currentUserName = authViewModel.currentUserName else { return }
        
        // Compute a stable chatId from the current user's name and the selected user's name
        let sortedNames = [currentUserName, user.name].sorted()
        let newChatId = "\(sortedNames[0])_\(sortedNames[1])"
        
        // Update the chatId in the view model
        viewModel.updateChatId(to: newChatId)
    }
    
    private func sendMessage() {
        let trimmedText = viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Send the message via ChatViewModel
        viewModel.sendMessage()
        
        // Clear the input field
        viewModel.newMessage = ""
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        // Initialize mock environment objects
        let authVM = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let imgMgr = ImageManager(scoreManager: scoreMgr)
        let chatVM = ChatViewModel(chatId: "TestChatId", authViewModel: authVM)
        
        ChatView(viewModel: chatVM)
            .environmentObject(authVM)
            .environmentObject(scoreMgr)
            .environmentObject(imgMgr)
    }
}
