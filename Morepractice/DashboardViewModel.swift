// DashboardViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine


// MARK: - DashboardViewModel

class DashboardViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    private var db = Firestore.firestore()
    private var authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        // Observe authentication state changes
        authViewModel.$currentUserName
            .sink { [weak self] userName in
                guard let self = self else { return }
                if let userName = userName {
                    self.fetchUserProfile(userName: userName)
                } else {
                    // User signed out, clear currentUser
                    DispatchQueue.main.async {
                        self.currentUser = nil
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchUserProfile(userName: String) {
        db.collection("users").document(userName).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user profile for \(userName): \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let email = data["email"] as? String,
                  let isOnline = data["isOnline"] as? Bool,
                  let uid = data["uid"] as? String,
                  let similarityScore = data["similarity_score"] as? Double else {
                print("Incomplete user data for \(userName)")
                return
            }
            
            let appUser = AppUser(
                id: uid,                   // Assigning UID as the unique identifier
                name: userName,
                email: email,
                isOnline: isOnline,
                uid: uid, similarityScore: similarityScore                   // Firebase UID
            )
            
            DispatchQueue.main.async {
                self?.currentUser = appUser
            }
        }
    }
}
