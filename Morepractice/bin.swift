// AuthViewModel.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var currentUserName: String?
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        userSession = Auth.auth().currentUser
        fetchUser()
        
        // Listen to authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.userSession = user
            self?.fetchUser()
        }
    }
    
    /// Fetches the current user's data from Firestore.
    func fetchUser() {
        guard let user = userSession else {
            self.currentUser = nil
            return
        }
        
        db.collection("users").document(user.displayName ?? user.uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            let user = AppUser(
                id: data["uid"] as? String ?? "",
                username: snapshot?.documentID ?? "",
                email: data["email"] as? String ?? "",
                isOnline: data["isOnline"] as? Bool ?? false,
                uid: data["uid"] as? String ?? "",
                profilePictureURL: data["profilePictureURL"] as? String ?? "",
                totalUploads: data["totalUploads"] as? Int ?? 0,
                totalScores: data["totalScores"] as? Int ?? 0,
                imagePreference: data["imagePreference"] as? [String: Double] ?? [:]
            )
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.currentUserName = user.username
            }
        }
    }
    
    /// Updates the user's profile picture URL in Firestore.
    func updateProfilePictureURL(url: String, completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        
        db.collection("users").document(user.username).updateData([
            "profilePictureURL": url
        ]) { error in
            if let error = error {
                print("Error updating profile picture URL: \(error.localizedDescription)")
                completion(false)
            } else {
                self.fetchUser()
                completion(true)
            }
        }
    }
    
    /// Handles user sign-out.
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.userSession = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct AppUser: Identifiable {
    var id: String
    var username: String
    var email: String
    var isOnline: Bool
    var uid: String
    var profilePictureURL: String
    var totalUploads: Int
    var totalScores: Int
    var imagePreference: [String: Double]
}

