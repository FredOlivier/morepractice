//
//  FriendSearchView.swift
//  Morepractice
//
//  Created by Fred Olivier on [date].
//

import SwiftUI
import FirebaseFirestore

struct FriendSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText: String = ""
    @State private var foundUser: String? = nil
    @State private var requestStatus: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
            
            Button("Search") {
                searchForUser(username: searchText)
            }
            .padding()
            .background(Color.blue.opacity(0.3))
            .cornerRadius(8)
            
            if let user = foundUser {
                HStack {
                    Text("Found: \(user)")
                    Spacer()
                    Button("Add Friend") {
                        sendFriendRequest(to: user)
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(8)
                }
                .padding([.leading, .trailing])
            }
            
            if !requestStatus.isEmpty {
                Text(requestStatus)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .navigationTitle("Search for Friends")
        .padding()
    }
    
    // MARK: - Firestore Search
    
    private func searchForUser(username: String) {
        let db = Firestore.firestore()
        db.collection("users").document(username).getDocument { snapshot, error in
            if let error = error {
                print("Error searching for user: \(error.localizedDescription)")
                self.foundUser = nil
            } else if let snapshot = snapshot, snapshot.exists {
                // User found, we use the documentID as the username.
                self.foundUser = snapshot.documentID
            } else {
                self.foundUser = nil
            }
        }
    }
    
    // MARK: - Send Friend Request
    
    private func sendFriendRequest(to receiver: String) {
        guard let sender = authViewModel.currentUser?.username else {
            self.requestStatus = "Sender information unavailable."
            return
        }
        FriendManager.shared.sendFriendRequest(from: sender, to: receiver) { error in
            if let error = error {
                self.requestStatus = "Error: \(error.localizedDescription)"
            } else {
                self.requestStatus = "Friend request sent successfully!"
                // Optionally clear the result to refresh the UI.
                self.foundUser = nil
            }
        }
    }
}

struct FriendSearchView_Previews: PreviewProvider {
    struct TestRootView: View {
        @StateObject var authViewModel = AuthViewModel()
        var body: some View {
            NavigationStack {
                FriendSearchView()
                    .environmentObject(authViewModel)
            }
        }
    }
    static var previews: some View {
        TestRootView()
    }
}
