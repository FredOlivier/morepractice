import Foundation
import SwiftUI
import FirebaseFirestore

/// A simpler or custom persistent chat referencing `persistent_text_chats/{docID}/messages`.
public struct PersistentChatView: View {
    public let chatRecord: PersistentChatRecord
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var appViewModel: AppViewModel

    // State for local message sending
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""

    private var db = Firestore.firestore()
    @State private var listener: ListenerRegistration?

    /// Explicit public initializer to avoid "private init" issues
     init(chatRecord: PersistentChatRecord) {
        self.chatRecord = chatRecord
    }

    public var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { msg in
                    HStack {
                        if msg.sender == authViewModel.currentUser?.username {
                            Spacer()
                            Text(msg.content)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(msg.content)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                }
            }
            .onAppear { observeMessages() }
            .onDisappear { listener?.remove() }

            // Input row
            HStack {
                TextField("Enter message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat with \(otherUserName())")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // Optional home button
                NavigationLink(destination: CircleDashboardView()
                    .environmentObject(authViewModel)
                    .environmentObject(scoreManager)
                    .environmentObject(mediaManager)
                    .environmentObject(appViewModel)
                ) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Firestore Observing

    private func observeMessages() {
        listener?.remove()
        db.collection("persistent_text_chats")
            .document(chatRecord.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snap, err in
                if let err = err {
                    print("PersistentChatView: error observing messages: \(err.localizedDescription)")
                    return
                }
                guard let docs = snap?.documents else { return }

                var newList: [ChatMessage] = []
                for d in docs {
                    let data = d.data()
                    if let sender = data["sender"] as? String,
                       let content = data["content"] as? String,
                       let ts = data["timestamp"] as? Timestamp {
                        let msg = ChatMessage(
                            id: d.documentID,
                            sender: sender,
                            content: content,
                            timestamp: ts.dateValue()
                        )
                        newList.append(msg)
                    }
                }
                DispatchQueue.main.async {
                    self.messages = newList
                }
            }
    }

    // MARK: - Send

    private func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let me = authViewModel.currentUser?.username else { return }

        let msgData: [String: Any] = [
            "sender": me,
            "content": trimmed,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("persistent_text_chats")
            .document(chatRecord.id)
            .collection("messages")
            .addDocument(data: msgData) { err in
                if let err = err {
                    print("PersistentChatView: error sending message: \(err.localizedDescription)")
                } else {
                    self.newMessage = ""
                    // Optionally update a "lastMessagePreview" in the chat doc
                    db.collection("persistent_text_chats")
                        .document(chatRecord.id)
                        .updateData(["lastMessagePreview": trimmed])
                }
            }
    }

    // MARK: - Helpers

    private func otherUserName() -> String {
        guard let myName = authViewModel.currentUser?.username else { return "Unknown" }
        return (chatRecord.user1 == myName) ? chatRecord.user2 : chatRecord.user1
    }
}

// MARK: - ChatMessage Model
public struct ChatMessage: Identifiable, Hashable {
    public let id: String
    public let sender: String
    public let content: String
    public let timestamp: Date
}
