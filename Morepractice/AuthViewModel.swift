//
//  AuthViewModel.swift
//  Morepractice
//
//  Created by Fred Olivier on … (updated 2025‑04‑22).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI
import FirebaseStorage

class AuthViewModel: ObservableObject {

    // MARK: - Published
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published var isSignedIn: Bool = false      // tracks sign‑in state

    // MARK: - Private
    private lazy var db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatTimer: Timer?

    // MARK: - AppUser model (NEW fields added)
    struct AppUser: Identifiable {
        var id:             String      // Firestore doc ID (publicUsername)
        var uid:            String
        var username:       String      // kept for compatibility (== publicUsername)
        var firstName:      String
        var lastName:       String
        var gender:         String
        var email:          String
        var isOnline:       Bool
        var lastActive:     Date?
        var lastSeen:       Date?
        var profilePictureURL: String
        var totalUploads:   Int
        var totalScores:    Int
        var imagePreference:[String:Double]
    }

    // MARK: - Init
    init() {
        //----------------------------------------------------------
        // 1. Firebase auth state listener
        //----------------------------------------------------------
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.userSession = user

                if let user = user {
                    print("AuthViewModel: signed in \(user.uid)")
                    self.fetchUser(uid: user.uid) { success in
                        self.isSignedIn = success
                        if success {
                            self.setUserOnline(true)
                            self.startHeartbeat()
                        } else {
                            self.currentUser = nil
                            self.setUserOnline(false)
                            self.stopHeartbeat()
                        }
                    }
                } else {
                    print("AuthViewModel: signed out.")
                    self.isSignedIn  = false
                    self.currentUser = nil
                    self.setUserOnline(false)
                    self.stopHeartbeat()
                }
            }
        }

        //----------------------------------------------------------
        // 2. App foreground / background notifications
        //----------------------------------------------------------
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.setUserOnline(false)
                self?.stopHeartbeat()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.userSession != nil {
                    self.setUserOnline(true)
                    self.startHeartbeat()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        heartbeatTimer?.invalidate()
    }

    // MARK: - HEARTBEAT (unchanged)
    public func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateLastActive()
        }
        updateLastActive()
    }

    public func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func updateLastActive() {
        guard let cu = currentUser else { return }
        db.collection("users").document(cu.username)
            .updateData(["lastActive": Timestamp(date: Date())])
    }

    // MARK: - FETCH USER DATA
    func fetchUser(uid: String, completion: @escaping (Bool)->Void) {
        db.collection("users").whereField("uid", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { completion(false); return }

                if let error = error { print(error); completion(false); return }
                guard let doc = snapshot?.documents.first else { completion(false); return }

                let d = doc.data()
                DispatchQueue.main.async {
                    self.currentUser = AppUser(
                        id:                 doc.documentID,
                        uid:                d["uid"] as? String ?? "",
                        username:           doc.documentID,
                        firstName:          d["firstName"] as? String ?? "",
                        lastName:           d["lastName"] as? String ?? "",
                        gender:             d["gender"] as? String ?? "",
                        email:              d["email"] as? String ?? "",
                        isOnline:           d["isOnline"] as? Bool ?? false,
                        lastActive:         (d["lastActive"] as? Timestamp)?.dateValue(),
                        lastSeen:           (d["last_seen"] as? Timestamp)?.dateValue(),
                        profilePictureURL:  d["profilePictureURL"] as? String ?? "",
                        totalUploads:       d["totalUploads"] as? Int ?? 0,
                        totalScores:        d["totalScores"]  as? Int ?? 0,
                        imagePreference:    d["imagePreference"] as? [String:Double] ?? [:]
                    )
                    completion(true)
                }
            }
    }

    // MARK: - SIGN UP  (new overload retains old API)
    /// New full sign‑up
    func signUp(
        firstName:      String,
        lastName:       String,
        publicUsername: String,
        gender:         String,
        email:          String,
        password:       String,
        completion:     @escaping (Error?)->Void
    ) {
        let userRef = db.collection("users").document(publicUsername)

        // Check username availability
        userRef.getDocument { snapshot, err in
            if let err = err { completion(err); return }
            if snapshot?.exists == true {
                completion(NSError(domain:"",code:409,userInfo:[NSLocalizedDescriptionKey:"Username taken"]))
                return
            }

            // Firebase createUser
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error { completion(error); return }
                guard let u = result?.user else {
                    completion(NSError(domain:"",code:-1,userInfo:nil)); return
                }

                let data: [String:Any] = [
                    "uid":               u.uid,
                    "email":             email,
                    "firstName":         firstName,
                    "lastName":          lastName,
                    "publicUsername":    publicUsername,
                    "gender":            gender,
                    "isOnline":          true,
                    "lastActive":        Timestamp(date: Date()),
                    "totalUploads":      0,
                    "totalScores":       0,
                    "imagePreference":   [:],
                    "profilePictureURL": ""
                ]
                userRef.setData(data) { error in completion(error) }
            }
        }
    }

    /// OLD short sign‑up kept for backward compatibility
    func signUp(name: String, email: String, password: String, completion: @escaping (Error?)->Void) {
        signUp(firstName: name,
               lastName:  "",
               publicUsername: name,
               gender:    "Prefer not to say",
               email:     email,
               password:  password,
               completion: completion)
    }

    // MARK: - ONLINE STATUS
    func setUserOnline(_ online: Bool) {
        guard let cu = currentUser else { return }
        let ref = db.collection("users").document(cu.username)
        if online {
            ref.updateData(["isOnline": true, "lastActive": Timestamp(date: Date())])
        } else {
            ref.updateData(["isOnline": false, "last_seen": FieldValue.serverTimestamp()])
        }
    }

    // MARK: - SIGN IN / OUT  (unchanged)
    func signIn(email: String, password: String, completion: @escaping (Bool,Error?)->Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, err in
            DispatchQueue.main.async { completion(err == nil, err) }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            setUserOnline(false)
            stopHeartbeat()
        } catch { print("Sign‑out error:", error) }
    }

    // MARK: - Profile picture helpers remain unchanged …
    // (omitted here only for brevity – keep your existing implementation)
}
