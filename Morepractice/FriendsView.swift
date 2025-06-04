//
//  FriendsView.swift
//  Morepractice
//
//  Created by Fred Olivier on 26/12/2024.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Data Models

struct Friend: Identifiable, Codable {
    @DocumentID var id: String?
    var friendUsername: String
    var timestamp: Timestamp
}

// Adjusted to match Firestore field "sender"
struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var sender: String
    var timestamp: Timestamp
}

// MARK: - FriendsView

struct FriendsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var friends: [Friend] = []
    @State private var friendRequests: [FriendRequest] = []
    @State private var friendStatuses: [String: Bool] = [:]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Navigation link to Friend Search.
                NavigationLink(destination: FriendSearchView().environmentObject(authViewModel)) {
                    Text("Search for Friends")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding()
                
                if !friendRequests.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Friend Requests")
                            .font(.headline)
                        List {
                            ForEach(friendRequests) { request in
                                HStack {
                                    Text(request.sender)
                                    Spacer()
                                    Button(action: { acceptRequest(request) }) {
                                        Image(systemName: "checkmark.circle")
                                    }
                                    .buttonStyle(.plain)
                                    Button(action: { declineRequest(request) }) {
                                        Image(systemName: "xmark.circle")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                List {
                    ForEach(friends) { friend in
                        HStack {
                            Text(friend.friendUsername)
                            Spacer()
                            if let online = friendStatuses[friend.friendUsername], online {
                                Text("Online").foregroundColor(.green)
                            } else {
                                Text("Offline").foregroundColor(.red)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("Friends")
            .onAppear {
                fetchFriends()
                fetchFriendRequests()
            }
        }
        // Force-inject AuthViewModel so that any child view that references it will not crash.
        .environmentObject(authViewModel)
    }
    
    // MARK: - Fetching Data
    private func fetchFriends() {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        let col = Firestore.firestore().collection("users").document(currentUsername).collection("friends")
        col.order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching friends: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.friends = documents.compactMap { try? $0.data(as: Friend.self) }
                updateStatuses()
            }
    }
    
    private func fetchFriendRequests() {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        let col = Firestore.firestore().collection("users").document(currentUsername).collection("friend_requests")
        col.order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching friend requests: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.friendRequests = documents.compactMap { try? $0.data(as: FriendRequest.self) }
            }
    }
    
    // MARK: - Online Status Updates
    private func updateStatuses() {
        for friend in friends {
            let username = friend.friendUsername
            Firestore.firestore().collection("users").document(username)
                .getDocument { snap, _ in
                    if let isOnline = snap?.data()?[
                        "isOnline"] as? Bool {
                        friendStatuses[username] = isOnline
                    }
                }
        }
    }
    
    // MARK: - Actions
    private func acceptRequest(_ request: FriendRequest) {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        FriendManager.shared.acceptFriendRequest(from: request.sender,
                                                 currentUsername: currentUsername) { error in
            if let error = error {
                print("Error accepting friend request: \(error.localizedDescription)")
            }
        }
    }
    
    private func declineRequest(_ request: FriendRequest) {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        FriendManager.shared.declineFriendRequest(from: request.sender,
                                                  currentUsername: currentUsername) { error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            }
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    struct TestRootView: View {
        @StateObject var authViewModel = AuthViewModel()
        var body: some View {
            NavigationStack {
                FriendsView()
                    .environmentObject(authViewModel)
            }
        }
    }
    static var previews: some View {
        TestRootView()
    }
}
