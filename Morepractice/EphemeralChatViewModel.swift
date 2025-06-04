//
//  EphemeralChatViewModel.swift
//  Morepractice
//
//  Created by Example on 17/09/2024.
//
/*
import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - ChatMessage Model
struct ChatMessage: Identifiable, Hashable {
    let id: String
    let sender: String
    let content: String
    let timestamp: Date
}



// MARK: - EphemeralChatViewModel
class EphemeralChatViewModel: ChatViewModelProtocol {
    // MARK: - Required by ChatViewModelProtocol
    @Published var chatId: String
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""

    let authViewModel: AuthViewModel

    var id: String { chatId } // for Identifiable

    // MARK: - Additional Ephemeral-Specific
    @Published var user1Name: String       // e.g., "Alice"
    @Published var user2Name: String       // e.g., "Bob"

    @Published var isEphemeral: Bool       // default true
    @Published var expiresAt: Date?        // optional expiration time

    private var db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?

    // MARK: - Initializer
    init(
        chatId: String,
        authViewModel: AuthViewModel,
        isEphemeral: Bool = true,
        expiresAt: Date? = nil,
        user1Name: String = "",
        user2Name: String = ""
    ) {
        self.chatId = chatId
        self.authViewModel = authViewModel
        self.isEphemeral = isEphemeral
        self.expiresAt = expiresAt
        self.user1Name = user1Name
        self.user2Name = user2Name

        // Start listening for messages
        observeMessages()

        // If ephemeral, schedule auto-expiration
        if isEphemeral, let realExpires = expiresAt {
            scheduleEphemeralCheck(at: realExpires)
        }
    }

    deinit {
        messagesListener?.remove()
    }

    // MARK: - Firestore Observation
    private func observeMessages() {
        // Remove old listener if any
        messagesListener?.remove()

        messagesListener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("EphemeralChatViewModel: Error observing messages: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let fetched = documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard
                        let sender = data["sender"] as? String,
                        let content = data["content"] as? String,
                        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
                    else {
                        return nil
                    }
                    return ChatMessage(
                        id: doc.documentID,
                        sender: sender,
                        content: content,
                        timestamp: timestamp
                    )
                }
                DispatchQueue.main.async {
                    self?.messages = fetched
                }
            }
    }

    // MARK: - Send Message
    func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let senderName = authViewModel.currentUser?.username
        let messageData: [String: Any] = [
            "sender": senderName,
            "content": trimmed,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .addDocument(data: messageData) { [weak self] error in
                if let error = error {
                    print("EphemeralChatViewModel: Error sending message: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.newMessage = ""
                    }
                }
            }
    }

    // MARK: - Ephemeral Logic
    private func scheduleEphemeralCheck(at expiry: Date) {
        let interval = expiry.timeIntervalSince(Date())
        guard interval > 0 else {
            handleExpiration()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.handleExpiration()
        }
    }

    private func handleExpiration() {
        if isEphemeral {
            db.collection("chats").document(chatId)
                .updateData(["isActive": false]) { err in
                    if let err = err {
                        print("EphemeralChatViewModel: Error marking chat inactive: \(err)")
                    } else {
                        print("EphemeralChatViewModel: Chat \(self.chatId) expired.")
                    }
                }
            // Optionally notify UI, remove self, etc.
        }
    }
}
 /**/*/
