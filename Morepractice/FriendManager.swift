//
//  FriendManager.swift
//  Morepractice
//
//  Created by Fred Olivier on [date].
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FriendManager {
    static let shared = FriendManager()
    
    
    private let db = Firestore.firestore()
    
    // MARK: - Send Friend Request
    
    /// Sends a friend request from the sender to the receiver.
    ///
    /// - Parameters:
    ///   - sender: The username of the sender.
    ///   - receiver: The username of the receiver.
    ///   - completion: A closure called with an optional error once the request is written.
    func sendFriendRequest(from sender: String, to receiver: String, completion: @escaping (Error?) -> Void) {
        // Data for the friend request document.
        let requestData: [String: Any] = [
            "sender": sender,
            "receiver": receiver,
            "timestamp": Timestamp(date: Date()),
            "status": "pending"
        ]
        
        // Create friend request document in the receiver’s "friend_requests" subcollection.
        db.collection("users").document(receiver).collection("friend_requests").document(sender).setData(requestData) { error in
            if let error = error {
                print("Error sending friend request (receiver side): \(error.localizedDescription)")
                completion(error)
            } else {
                print("Friend request document created in \(receiver)'s friend_requests.")
                // Also create a record in the sender’s "sent_requests" subcollection.
                let sentData: [String: Any] = [
                    "receiver": receiver,
                    "timestamp": Timestamp(date: Date()),
                    "status": "pending"
                ]
                self.db.collection("users").document(sender).collection("sent_requests").document(receiver).setData(sentData) { error in
                    if let error = error {
                        print("Error saving friend request (sender side): \(error.localizedDescription)")
                    } else {
                        print("Friend request document saved in \(sender)'s sent_requests.")
                    }
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - Accept Friend Request
    
    /// Accepts a friend request sent by the sender.
    /// Creates mutual friend documents for both users and deletes the friend request.
    ///
    /// - Parameters:
    ///   - senderUsername: The username of the user who sent the request.
    ///   - currentUsername: The current user's username.
    ///   - completion: An optional closure called with an optional error when finished.
    func acceptFriendRequest(from senderUsername: String, currentUsername: String, completion: ((Error?) -> Void)? = nil) {
        let friendDataForCurrent: [String: Any] = [
            "friendUsername": senderUsername,
            "timestamp": Timestamp(date: Date())
        ]
        let friendDataForSender: [String: Any] = [
            "friendUsername": currentUsername,
            "timestamp": Timestamp(date: Date())
        ]
        
        let currentFriendRef = db.collection("users").document(currentUsername)
            .collection("friends").document(senderUsername)
        let senderFriendRef = db.collection("users").document(senderUsername)
            .collection("friends").document(currentUsername)
        
        let batch = db.batch()
        batch.setData(friendDataForCurrent, forDocument: currentFriendRef)
        batch.setData(friendDataForSender, forDocument: senderFriendRef)
        
        // Delete the friend request document from the current user’s friend_requests subcollection.
        let requestRef = db.collection("users").document(currentUsername)
            .collection("friend_requests").document(senderUsername)
        batch.deleteDocument(requestRef)
        
        batch.commit { error in
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            } else {
                print("Friend request accepted between \(currentUsername) and \(senderUsername)")
            }
            completion?(error)
        }
    }
    
    // MARK: - Decline Friend Request
    
    /// Declines a friend request by deleting it from the current user's friend_requests subcollection.
    ///
    /// - Parameters:
    ///   - senderUsername: The username of the user who sent the request.
    ///   - currentUsername: The current user's username.
    ///   - completion: An optional closure called with an optional error when finished.
    func declineFriendRequest(from senderUsername: String, currentUsername: String, completion: ((Error?) -> Void)? = nil) {
        let requestRef = db.collection("users").document(currentUsername)
            .collection("friend_requests").document(senderUsername)
        requestRef.delete { error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                print("Friend request from \(senderUsername) declined by \(currentUsername)")
            }
            completion?(error)
        }
    }
}
