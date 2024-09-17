// ScoreManager.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine


// MARK: - ScoreManager

class ScoreManager: ObservableObject {
    @Published var scores: [Score] = []
    @Published var imagePreference: [String: Double] = [:]
    @Published var similarUsers: [AppUser] = []

    private var db = Firestore.firestore()
    private var authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Define a fixed similarity threshold
    private let fixedSimilarityThreshold: Double = 0.5

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel

        // Observe changes in the current user's name
        authViewModel.$currentUserName
            .sink { [weak self] userName in
                guard let self = self else { return }
                if let userName = userName {
                    self.loadImagePreferences(for: userName)
                    self.observeScores(for: userName)
                    self.fetchSimilarUsers(for: userName)
                } else {
                    // User signed out, clear data
                    DispatchQueue.main.async {
                        self.scores = []
                        self.imagePreference = [:]
                        self.similarUsers = []
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Image Preferences

    private func loadImagePreferences(for userName: String) {
        db.collection("users").document(userName).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching image preferences for \(userName): \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(),
               let prefs = data["imagePreference"] as? [String: Double] {
                DispatchQueue.main.async {
                    self?.imagePreference = prefs
                    print("Image preferences loaded: \(prefs)")
                }
            } else {
                DispatchQueue.main.async {
                    self?.imagePreference = [:]
                    print("No image preferences found for \(userName).")
                }
            }
        }
    }

    // MARK: - Scores Observation

    func observeScores(for userName: String) {
        db.collection("users").document(userName).collection("scores").order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error observing scores for \(userName): \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                var updatedScores: [Score] = []

                for document in documents {
                    let data = document.data()
                    if let slider1 = data["slider1"] as? Double,
                       let slider2 = data["slider2"] as? Double,
                       let image1_id = data["image1_id"] as? String,
                       let image2_id = data["image2_id"] as? String,
                       let image1_url = data["image1_url"] as? String,
                       let image2_url = data["image2_url"] as? String,
                       let relational_score = data["relational_score"] as? Double,
                       let date = (data["date"] as? Timestamp)?.dateValue() {

                        let score = Score(
                            id: document.documentID,
                            slider1: slider1,
                            slider2: slider2,
                            image1: image1_id,
                            image2: image2_id,
                            image1URL: image1_url,
                            image2URL: image2_url,
                            relationalScore: relational_score,
                            date: date
                        )
                        updatedScores.append(score)
                    } else {
                        print("Incomplete score data in document: \(document.documentID)")
                    }
                }

                DispatchQueue.main.async {
                    self?.scores = updatedScores
                    self?.updateImagePreferences() // Recompute image preferences whenever scores are updated
                    print("Scores updated. Total scores: \(self?.scores.count ?? 0)")
                }
            }
    }

    // MARK: - Fetch Similar Users

    private func fetchSimilarUsers(for userName: String) {
        // Clear current similarUsers before fetching new ones
        DispatchQueue.main.async {
            self.similarUsers = []
            print("Cleared existing similar users.")
        }

        // Use the fixed similarity threshold
        let similarityThreshold = fixedSimilarityThreshold
        print("Using fixed Similarity Threshold: \(similarityThreshold)")
        self.fetchSimilarUsersWithThreshold(userName: userName, threshold: similarityThreshold)
    }

    private func fetchSimilarUsersWithThreshold(userName: String, threshold: Double) {
        let similaritiesRef = db.collection("similarities")
        
        // Query 1: user1_id == userName and similarity_score >= threshold
        let query1 = similaritiesRef
            .whereField("user1_id", isEqualTo: userName)
            .whereField("similarity_score", isGreaterThanOrEqualTo: threshold)
        
        // Query 2: user2_id == userName and similarity_score >= threshold
        let query2 = similaritiesRef
            .whereField("user2_id", isEqualTo: userName)
            .whereField("similarity_score", isGreaterThanOrEqualTo: threshold)
        
        let group = DispatchGroup()
        
        var similarUsersData: [(userName: String, similarityScore: Double)] = []
        
        group.enter()
        query1.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("Error fetching similarities as user1: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for doc in documents {
                let data = doc.data()
                if let user2 = data["user2_id"] as? String,
                   let similarity = data["similarity_score"] as? Double {
                    similarUsersData.append((userName: user2, similarityScore: similarity))
                }
            }
            print("Fetched \(similarUsersData.count) similarities from user1_id query.")
        }
        
        group.enter()
        query2.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("Error fetching similarities as user2: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for doc in documents {
                let data = doc.data()
                if let user1 = data["user1_id"] as? String,
                   let similarity = data["similarity_score"] as? Double {
                    similarUsersData.append((userName: user1, similarityScore: similarity))
                }
            }
            print("Fetched \(similarUsersData.count) similarities from user2_id query.")
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if similarUsersData.isEmpty {
                print("No similar users found with threshold \(threshold)")
                return
            }
            
            // Remove duplicates by keeping the highest similarity score
            var uniqueSimilarUsers: [String: Double] = [:]
            for (userName, similarityScore) in similarUsersData {
                if let existingScore = uniqueSimilarUsers[userName] {
                    if similarityScore > existingScore {
                        uniqueSimilarUsers[userName] = similarityScore
                    }
                } else {
                    uniqueSimilarUsers[userName] = similarityScore
                }
            }
            
            print("Unique similar users after removing duplicates: \(uniqueSimilarUsers.count)")
            
            // Prepare to fetch all user profiles
            var fetchedUsers: [AppUser] = []
            let fetchGroup = DispatchGroup()
            
            for (similarUserName, similarityScore) in uniqueSimilarUsers {
                fetchGroup.enter()
                self.fetchUserProfile(userName: similarUserName, similarityScore: similarityScore) { user in
                    if let user = user {
                        fetchedUsers.append(user)
                        print("Fetched user profile for: \(user.name)")
                    }
                    fetchGroup.leave()
                }
            }
            
            fetchGroup.notify(queue: .main) {
                // Assign all fetched users at once to similarUsers
                self.similarUsers = fetchedUsers
                print("Total similar users fetched and assigned: \(self.similarUsers.count)")
            }
        }
    }

    private func fetchUserProfile(userName: String, similarityScore: Double, completion: @escaping (AppUser?) -> Void) {
        db.collection("users").document(userName).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile for \(userName): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data(),
                  let email = data["email"] as? String,
                  let isOnline = data["isOnline"] as? Bool,
                  let uid = data["uid"] as? String else {
                print("Incomplete user data for \(userName)")
                completion(nil)
                return
            }
            
            let user = AppUser(
                id: uid,
                name: userName,
                email: email,
                isOnline: isOnline, uid: uid,
                similarityScore: similarityScore
            )
            
            completion(user)
        }
    }

    // MARK: - Update Image Preferences

    private func updateImagePreferences() {
        var imageData: [String: (sum: Double, count: Int)] = [:]

        for score in scores {
            // Process image1
            if let entry = imageData[score.image1] {
                imageData[score.image1] = (entry.sum + score.slider1, entry.count + 1)
            } else {
                imageData[score.image1] = (score.slider1, 1)
            }

            // Process image2
            if let entry = imageData[score.image2] {
                imageData[score.image2] = (entry.sum + score.slider2, entry.count + 1)
            } else {
                imageData[score.image2] = (score.slider2, 1)
            }
        }

        var updatedPreferences: [String: Double] = [:]

        for (imageId, data) in imageData {
            let average = data.sum / Double(data.count)
            updatedPreferences[imageId] = average
        }

        // Update the published property
        DispatchQueue.main.async {
            self.imagePreference = updatedPreferences
            print("Image preferences updated: \(updatedPreferences)")
        }

        // Update Firestore
        guard let userName = authViewModel.currentUserName else { return }

        db.collection("users").document(userName).updateData([
            "imagePreference": updatedPreferences
        ]) { error in
            if let error = error {
                print("Error updating image preferences for \(userName): \(error.localizedDescription)")
            } else {
                print("Image preferences updated successfully for \(userName).")
            }
        }
    }

    // MARK: - Add Score

    func addScore(slider1: Double, slider2: Double, image1: String, image2: String, image1URL: String, image2URL: String, relationalScore: Double) {
        guard let userName = authViewModel.currentUserName else {
            print("Error: User is not signed in.")
            return
        }

        let scoreID = UUID().uuidString
        let scoreData: [String: Any] = [
            "slider1": slider1,
            "slider2": slider2,
            "image1_id": image1,
            "image2_id": image2,
            "image1_url": image1URL,
            "image2_url": image2URL,
            "relational_score": relationalScore,
            "date": Timestamp(date: Date())
        ]

        db.collection("users").document(userName).collection("scores").document(scoreID).setData(scoreData) { [weak self] error in
            if let error = error {
                print("Error adding score for \(userName): \(error.localizedDescription)")
            } else {
                // No longer need to call updateImagePreferences here since it's called in observeScores
                print("Score added successfully for \(userName).")
            }
        }
    }
}
