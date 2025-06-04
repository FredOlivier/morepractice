// AutoChatManager.swift
/*
import Foundation
import FirebaseFirestore
import Combine

class AutoChatManager: ObservableObject {
    // Timer for periodic checks
    private var timer: Timer?
    // For testing, check every 10 seconds
    private let checkInterval: TimeInterval = 10.0

    private let highThreshold: Double = 0.6
    private let lowThreshold: Double = 0.5
    // For testing, short cooldown, e.g. 10 seconds
    private let cooldownDuration: TimeInterval = 10.0

    private let authViewModel: AuthViewModel
    private let scoreManager: ScoreManager
    private let db = Firestore.firestore()

    // Publishes newly created ephemeral chat view models
    let ephemeralChatPublisher = PassthroughSubject<EphemeralChatViewModel, Never>()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(authViewModel: AuthViewModel, scoreManager: ScoreManager) {
        self.authViewModel = authViewModel
        self.scoreManager = scoreManager

        // Listen for sign-in state changes
        authViewModel.$userSession
            .sink { [weak self] user in
                if user != nil {
                    self?.startPeriodicChecks()
                } else {
                    self?.stopPeriodicChecks()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        stopPeriodicChecks()
    }

    // MARK: - Periodic Checks
    func startPeriodicChecks() {
        stopPeriodicChecks()  // Ensure only one timer is running
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.attemptAutoChat()
        }
        print("AutoChatManager: Started periodic checks every \(checkInterval) seconds.")
        
        // Immediate attempt
        attemptAutoChat()
    }

    func stopPeriodicChecks() {
        timer?.invalidate()
        timer = nil
        print("AutoChatManager: Stopped periodic checks.")
    }

    // MARK: - Auto-Chat Logic
    private func attemptAutoChat() {
        // Corrected: Access username via currentUser?.username
        guard let currentUserName = authViewModel.currentUser?.username,
              authViewModel.userSession != nil else {
            print("AutoChat: No current user or userSession is nil.")
            return
        }
        // Confirm current user is online
        isUserOnline(username: currentUserName) { [weak self] isOnline in
            guard let self = self else { return }
            if isOnline {
                // Fetch top similar users
                self.fetchTopSimilarUsers(for: currentUserName) { candidates in
                    self.checkCooldownAndConnect(currentUser: currentUserName, candidates: candidates)
                }
            } else {
                print("AutoChat: Current user is offline; skipping auto chat.")
            }
        }
    }

    // MARK: - Online Status
    private func isUserOnline(username: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(username).getDocument { snap, err in
            if let err = err {
                print("AutoChat: Error fetching user online status: \(err.localizedDescription)")
                completion(false)
                return
            }
            guard let data = snap?.data(),
                  let isOnline = data["isOnline"] as? Bool,
                  let lastActive = data["lastActive"] as? Timestamp else {
                print("AutoChat: Missing 'isOnline' or 'lastActive' for user \(username).")
                completion(false)
                return
            }
            let lastActiveDate = lastActive.dateValue()
            let timeSinceLastActive = Date().timeIntervalSince(lastActiveDate)
            // Online if isOnline && lastActive within last 120 seconds
            let online = isOnline && (timeSinceLastActive < 120)
            completion(online)
        }
    }

    // MARK: - Fetch Similar Users
    private func fetchTopSimilarUsers(for userName: String, completion: @escaping ([(String, Double)]) -> Void) {
        let ref = db.collection("similarities")
        var results: [(String, Double)] = []
        let group = DispatchGroup()
        
        // Query 1
        group.enter()
        ref.whereField("user1_id", isEqualTo: userName).getDocuments { snap, err in
            defer { group.leave() }
            if let err = err {
                print("AutoChatManager: Error fetching similarities as user1 - \(err.localizedDescription)")
                return
            }
            guard let docs = snap?.documents else { return }
            for doc in docs {
                let data = doc.data()
                if let user2 = data["user2_id"] as? String,
                   let sim = data["similarity_score"] as? Double {
                    results.append((user2, sim))
                }
            }
        }

        // Query 2
        group.enter()
        ref.whereField("user2_id", isEqualTo: userName).getDocuments { snap, err in
            defer { group.leave() }
            if let err = err {
                print("AutoChatManager: Error fetching similarities as user2 - \(err.localizedDescription)")
                return
            }
            guard let docs = snap?.documents else { return }
            for doc in docs {
                let data = doc.data()
                if let user1 = data["user1_id"] as? String,
                   let sim = data["similarity_score"] as? Double {
                    results.append((user1, sim))
                }
            }
        }

        group.notify(queue: .main) {
            // sort descending
            let sorted = results.sorted { $0.1 > $1.1 }
            completion(sorted)
        }
    }

    // MARK: - Cooldown & Connection
    private func checkCooldownAndConnect(currentUser: String, candidates: [(String, Double)]) {
        var fallbackCandidate: (String, Double)? = nil

        for (otherUser, sim) in candidates {
            if sim < lowThreshold { break }
            
            isUserOnline(username: otherUser) { [weak self] otherOnline in
                guard let self = self else { return }
                if !otherOnline { return }

                self.isOnCooldown(userA: currentUser, userB: otherUser) { onCooldown in
                    if onCooldown { return }

                    if sim >= self.highThreshold {
                        print("AutoChatManager: Found user \(otherUser) w/ sim \(sim) >= \(self.highThreshold). Initiating ephemeral chat.")
                        self.createOrGetEphemeralChat(userA: currentUser, userB: otherUser)
                    } else if sim >= self.lowThreshold {
                        // fallback if none chosen
                        if fallbackCandidate == nil {
                            fallbackCandidate = (otherUser, sim)
                        }
                    }
                }
            }
        }
        
        // Fallback after 2 seconds if no high-sim user found
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if let (fallbackUser, fallbackSim) = fallbackCandidate {
                print("AutoChatManager: Using fallback candidate \(fallbackUser) sim=\(fallbackSim).")
                self.createOrGetEphemeralChat(userA: currentUser, userB: fallbackUser)
            } else {
                print("AutoChatManager: No suitable ephemeral chat candidate found.")
            }
        }
    }

    private func isOnCooldown(userA: String, userB: String, completion: @escaping (Bool) -> Void) {
        let cdRef = db.collection("users").document(userA)
            .collection("cooldowns").document(userB)
        
        cdRef.getDocument { snap, err in
            if let err = err {
                print("AutoChatManager: Error reading cooldown doc for \(userA)->\(userB): \(err.localizedDescription)")
                completion(false)
                return
            }
            guard let data = snap?.data() else {
                completion(false)
                return
            }
            let nextAvail = (data["nextAvailableTime"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let now = Date()
            let timeCD = (now < nextAvail)
            if timeCD {
                print("AutoChatManager: \(userA)->\(userB) is on cooldown until \(nextAvail).")
            }
            completion(timeCD)
        }
    }

    // MARK: - Create or Reuse Ephemeral Chat
    private func createOrGetEphemeralChat(userA: String, userB: String) {
        // Deterministic chatId for ephemeral
        let sortedUsers = [userA, userB].sorted()
        let chatId = "\(sortedUsers[0])_\(sortedUsers[1])"

        let chatRef = db.collection("chats").document(chatId)
        chatRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("AutoChatManager: Error fetching chat \(chatId): \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.data(), let isActive = data["isActive"] as? Bool, isActive {
                // Chat exists & active
                print("AutoChatManager: Ephemeral chat \(chatId) already active, reusing.")
                let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date().addingTimeInterval(30)
                let ephemeralVM = EphemeralChatViewModel(
                    chatId: chatId,
                    authViewModel: self.authViewModel,
                    isEphemeral: true,
                    expiresAt: expiresAt
                )
                // Publish to app-level
                self.ephemeralChatPublisher.send(ephemeralVM)
            } else {
                // No active ephemeral chat doc => create a new one in a single batch
                self.batchCreateEphemeralChat(chatId: chatId, userA: userA, userB: userB)
            }
        }
    }

    // MARK: - Batching ephemeral chat creation + cooldown
    private func batchCreateEphemeralChat(chatId: String, userA: String, userB: String) {
        guard let userAUid = authViewModel.userSession?.uid else {
            print("AutoChatManager: userAUid not found. Cannot create ephemeral chat.")
            return
        }
        // fetch userB's uid
        db.collection("users").document(userB).getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err {
                print("AutoChatManager: Error fetching userB doc: \(err.localizedDescription)")
                return
            }
            guard let data = snap?.data(), let userBUid = data["uid"] as? String else {
                print("AutoChatManager: No uid in userB doc.")
                return
            }
            
            let created = Date()
            let expires = created.addingTimeInterval(30) // ephemeral for 30s
            let chatRef = self.db.collection("chats").document(chatId)

            // Prepare chat data
            let chatData: [String: Any] = [
                "user1": userA,
                "user2": userB,
                "user1_uid": userAUid,
                "user2_uid": userBUid,
                "createdAt": Timestamp(date: created),
                "expiresAt": Timestamp(date: expires),
                "isActive": true,
                "isEphemeral": true
            ]
            
            // nextAvailable for cooldown
            let nextAvailTime = Date().addingTimeInterval(self.cooldownDuration)
            let cdData: [String: Any] = [
                "nextAvailableTime": Timestamp(date: nextAvailTime)
            ]
            
            let batch = self.db.batch()
            
            // 1) Create ephemeral chat doc
            batch.setData(chatData, forDocument: chatRef, merge: true)
            
            // 2) userA->userB cooldown
            let cdARef = self.db.collection("users")
                .document(userA)
                .collection("cooldowns")
                .document(userB)
            batch.setData(cdData, forDocument: cdARef, merge: true)
            
            // 3) userB->userA cooldown
            let cdBRef = self.db.collection("users")
                .document(userB)
                .collection("cooldowns")
                .document(userA)
            batch.setData(cdData, forDocument: cdBRef, merge: true)
            
            // 4) Commit once
            batch.commit { [weak self] commitErr in
                guard let self = self else { return }
                if let commitErr = commitErr {
                    print("AutoChatManager: Batch ephemeral chat creation failed: \(commitErr.localizedDescription)")
                } else {
                    print("AutoChatManager: Ephemeral chat \(chatId) + cooldown set in one batch.")
                    // Immediately publish the ephemeral VM to the app
                    let ephemeralVM = EphemeralChatViewModel(
                        chatId: chatId,
                        authViewModel: self.authViewModel,
                        isEphemeral: true,
                        expiresAt: expires
                    )
                    self.ephemeralChatPublisher.send(ephemeralVM)
                    
                    // optional: schedule auto-deactivate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                        self.deactivateChat(chatId: chatId)
                    }
                }
            }
        }
    }

    // MARK: - Deactivate Chat
    private func deactivateChat(chatId: String) {
        db.collection("chats").document(chatId)
            .updateData(["isActive": false]) { err in
                if let err = err {
                    print("AutoChatManager: Error deactivating chat \(chatId): \(err.localizedDescription)")
                } else {
                    print("AutoChatManager: Chat \(chatId) deactivated after 30 seconds.")
                }
            }
    }
 }*/
