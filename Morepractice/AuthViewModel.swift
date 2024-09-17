// AuthViewModel.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUserName: String?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private lazy var db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init() {
        // Listen for authentication state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.userSession = user
                if let user = user {
                    self?.fetchUserName(uid: user.uid)
                    self?.setUserOnline(true)
                    print("User signed in: \(user.uid)")
                } else {
                    self?.currentUserName = nil
                    print("User signed out.")
                }
            }
        }
        
        // Update online status based on app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.setUserOnline(false)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.userSession != nil {
                    self?.setUserOnline(true)
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Fetch Current User's Username
    
    /// Fetches the username (document ID) from Firestore based on the user's UID.
    /// - Parameter uid: The Firebase UID of the user.
    private func fetchUserName(uid: String) {
        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error fetching user name: \(error.localizedDescription)"
                    print("Error fetching user name: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self?.errorMessage = "No user found with UID: \(uid)"
                    print("No user found with UID: \(uid)")
                    return
                }
                
                let doc = documents.first!
                self?.currentUserName = doc.documentID
                print("Fetched user name: \(doc.documentID)")
            }
        }
    }
    
    // MARK: - Set User Online Status
    
    /// Sets the user's online status in Firestore.
    /// - Parameter online: A Boolean indicating whether the user is online.
    private func setUserOnline(_ online: Bool) {
        guard let name = currentUserName else { return }
        
        db.collection("users").document(name).updateData([
            "isOnline": online,
            "last_seen": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                self.errorMessage = "Error updating online status: \(error.localizedDescription)"
                print("Error updating online status: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sign Up Function
    
    /// Registers a new user with the provided details.
    /// - Parameters:
    ///   - name: The desired username.
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - completion: A closure that handles the result of the sign-up attempt.
    func signUp(name: String, email: String, password: String, completion: @escaping (Error?) -> Void) {
        let userDocRef = db.collection("users").document(name)
        userDocRef.getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error)
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    completion(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "This username is already taken."]))
                    return
                }
                
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(error)
                            return
                        }
                        
                        guard let user = authResult?.user else {
                            completion(NSError(domain: "User creation failed", code: -1, userInfo: nil))
                            return
                        }
                        
                        let userData: [String: Any] = [
                            "uid": user.uid,
                            "email": email,
                            "isOnline": true,
                            "created_at": Timestamp(date: Date())
                        ]
                        
                        userDocRef.setData(userData) { error in
                            if let error = error {
                                completion(error)
                                return
                            }
                            
                            self?.userSession = user
                            self?.currentUserName = name
                            self?.errorMessage = nil
                            print("Sign up successful for user: \(name)")
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sign In Function
    
    /// Signs in the user with the provided credentials.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - completion: A closure that handles the result of the sign-in attempt.
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Sign in failed: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                
                guard let user = result?.user else {
                    self?.errorMessage = "User data not found."
                    print("Sign in failed: User data not found.")
                    completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found."]))
                    return
                }
                
                self?.userSession = user
                self?.fetchUserName(uid: user.uid)
                self?.errorMessage = nil
                print("Sign in successful for user: \(user.uid)")
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Sign Out Function
    
    /// Signs out the current user.
    func signOut() {
        guard let name = currentUserName else { return }
        
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUserName = nil
            self.errorMessage = nil
            setUserOnline(false)
            print("Sign out successful.")
        } catch {
            self.errorMessage = "Error signing out: \(error.localizedDescription)"
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
