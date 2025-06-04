import Foundation
import SwiftUI
import FirebaseFirestore

struct ConnectionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsView: SettingsManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager

    @State private var topSimilarUsers: [AppUser] = []
    @State private var activeChats: [PersistentChatRecord] = []
    @State private var isLoaded: Bool = false

    let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1) Horizontal top bar
                if !topSimilarUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(topSimilarUsers, id: \.id) { user in
                                VStack {
                                    Text(user.name)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(6)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(8)
                                // Example: Optionally tap to open or create a chat
                                .onTapGesture {
                                    createOrOpenChat(with: user)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("No similar users found.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding()
                }

                Divider()

                // 2) List of existing chats
                if activeChats.isEmpty && isLoaded {
                    Text("No chats found with your top 7 users.")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List(activeChats, id: \.id) { chatRecord in
                        NavigationLink(
                            destination: PersistentChatView(chatRecord: chatRecord)
                                .environmentObject(authViewModel)
                                .environmentObject(scoreManager)
                                .environmentObject(mediaManager)
                                .environmentObject(appViewModel)
                        ) {
                            VStack(alignment: .leading) {
                                Text(otherUserName(from: chatRecord))
                                    .font(.headline)
                                Text(chatRecord.lastMessagePreview ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Connections")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: CircleDashboardView()
                        .environmentObject(authViewModel)
                        .environmentObject(scoreManager)
                        .environmentObject(mediaManager)
                        .environmentObject(appViewModel)
                        .environmentObject(settingsManager)
                        .environmentObject(linkingSettingsManager)
                    ) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Go to Dashboard")
                }
            }
            .onAppear {
                fetchTopSimilarUsers()
                fetchActiveChats()
            }
        }
    }

    // MARK: - Create or Open Chat for each top user
    private func createOrOpenChat(with user: AppUser) {
        guard let me = authViewModel.currentUser?.username else { return }
        let otherUser = user.name
        let docID = makeDocId(user1: me, user2: otherUser)

        // Check if doc already exists
        db.collection("persistent_text_chats")
            .document(docID)
            .getDocument { snap, err in
                if let snap = snap, snap.exists {
                    // Already exists => optionally push onto activeChats or just let user see it
                    print("Chat doc for \(docID) already exists")
                    // For demo, we don't forcibly navigate; you could do so here
                } else {
                    // Create new doc
                    let data: [String: Any] = [
                        "participants": [me, otherUser],
                        "user1_name": me,
                        "user2_name": otherUser,
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastMessagePreview": "",
                        // You could also store their UIDs if needed:
                        // "uid1": authViewModel.currentUser?.uid ?? "",
                        // "uid2": user.uid,
                    ]
                    db.collection("persistent_text_chats")
                        .document(docID)
                        .setData(data) { err2 in
                            if let err2 = err2 {
                                print("Error creating new chat doc: \(err2.localizedDescription)")
                            } else {
                                print("New chat doc created for \(me) & \(otherUser) => \(docID)")
                            }
                        }
                }
            }
    }

    // MARK: - For each top user, automatically create if missing
    // Optionally call this after we get topSimilarUsers
    private func createPersistentChatsForTopUsers(_ topUsers: [AppUser]) {
        guard let me = authViewModel.currentUser?.username else { return }

        for user in topUsers {
            let docID = makeDocId(user1: me, user2: user.name)
            let docRef = db.collection("persistent_text_chats").document(docID)
            docRef.getDocument { snap, err in
                if let snap = snap, snap.exists {
                    // Already present
                } else {
                    // Create doc
                    let data: [String: Any] = [
                        "participants": [me, user.name],
                        "user1_name": me,
                        "user2_name": user.name,
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastMessagePreview": ""
                    ]
                    docRef.setData(data) { err2 in
                        if let err2 = err2 {
                            print("Error creating new chat doc: \(err2.localizedDescription)")
                        } else {
                            print("New chat doc created: \(docID)")
                        }
                    }
                }
            }
        }
    }

    // Helper to ensure doc ID is consistent, e.g. "Anna_Ben"
    private func makeDocId(user1: String, user2: String) -> String {
        let sortedPair = [user1, user2].sorted()
        return sortedPair.joined(separator: "_")
    }

    // MARK: - Fetch 7 Most Similar Users
    private func fetchTopSimilarUsers() {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        let ref = db.collection("similarities")
        ref
            .whereField("user1_id", isEqualTo: currentUsername)
            .order(by: "similarity_score", descending: true)
            .limit(to: 7)
            .getDocuments { snap, err in
                if let err = err {
                    print("ConnectionsView: error fetching top users #1: \(err.localizedDescription)")
                    return
                }
                var userNames: [String] = []
                if let docs = snap?.documents {
                    for d in docs {
                        if let uname = d.data()["user2_id"] as? String {
                            userNames.append(uname)
                        }
                    }
                }

                // Also check reverse
                ref
                    .whereField("user2_id", isEqualTo: currentUsername)
                    .order(by: "similarity_score", descending: true)
                    .limit(to: 7)
                    .getDocuments { snap2, err2 in
                        if let err2 = err2 {
                            print("ConnectionsView: error fetching top users #2: \(err2.localizedDescription)")
                            return
                        }
                        if let docs2 = snap2?.documents {
                            for d2 in docs2 {
                                if let uname = d2.data()["user1_id"] as? String {
                                    userNames.append(uname)
                                }
                            }
                        }
                        let uniqueNames = Array(Set(userNames)).prefix(7)
                        fetchProfiles(for: Array(uniqueNames))
                    }
            }
    }

    private func fetchProfiles(for userNames: [String]) {
        let group = DispatchGroup()
        var fetchedUsers: [AppUser] = []

        for uname in userNames {
            group.enter()
            db.collection("users").document(uname).getDocument { snap, err in
                if let data = snap?.data() {
                    let appUser = AppUser(
                        id: data["uid"] as? String ?? "",
                        name: uname,
                        email: data["email"] as? String ?? "",
                        isOnline: data["isOnline"] as? Bool ?? false,
                        uid: data["uid"] as? String ?? "",
                        similarityScore: 0
                    )
                    fetchedUsers.append(appUser)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.topSimilarUsers = fetchedUsers.sorted { $0.name < $1.name }

            // Example: automatically create docs for them
            self.createPersistentChatsForTopUsers(self.topSimilarUsers)
        }
    }

    // MARK: - Fetch Active Chats
    private func fetchActiveChats() {
        guard let currentUsername = authViewModel.currentUser?.username else { return }
        let ref = db.collection("persistent_text_chats")
        ref
            .whereField("participants", arrayContains: currentUsername)
            .getDocuments { snap, err in
                self.isLoaded = true
                if let err = err {
                    print("ConnectionsView: error fetching persistent chats: \(err.localizedDescription)")
                    return
                }
                guard let docs = snap?.documents else { return }
                var results: [PersistentChatRecord] = []

                for d in docs {
                    let data = d.data()
                    if let participants = data["participants"] as? [String],
                       let user1 = data["user1_name"] as? String,
                       let user2 = data["user2_name"] as? String {
                        let lastPreview = data["lastMessagePreview"] as? String
                        let chatRec = PersistentChatRecord(
                            id: d.documentID,
                            user1: user1,
                            user2: user2,
                            participants: participants,
                            lastMessagePreview: lastPreview
                        )
                        results.append(chatRec)
                    }
                }
                self.activeChats = results.sorted {
                    let aOther = self.otherUserName(from: $0)
                    let bOther = self.otherUserName(from: $1)
                    return aOther < bOther
                }
            }
    }

    func otherUserName(from chat: PersistentChatRecord) -> String {
        guard let currentU = authViewModel.currentUser?.username else { return "Unknown" }
        return (chat.user1 == currentU) ? chat.user2 : chat.user1
    }
}

public struct PersistentChatRecord: Identifiable {
    public let id: String
    public let user1: String
    public let user2: String
    public let participants: [String]
    public let lastMessagePreview: String?
}

