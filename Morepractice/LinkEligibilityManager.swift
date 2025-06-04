import Foundation
import FirebaseFirestore

/// Represents a candidate user and their similarity score.
private struct Candidate {
    let username: String
    let similarity: Double
}

/// Manages selecting eligible users for WebRTC linking based on similarity thresholds.
class LinkEligibilityManager {
    static let shared = LinkEligibilityManager()
    private let db = Firestore.firestore()

    /// Default similarity threshold for “basic” eligibility.
    private let basicThreshold: Double = 0.2
    /// Minimum score for tag-based eligibility.
    private let tagThreshold: Double = 0.004

    private init() {}

    /**
     Fetches eligible users for linking based on selected modes.
     - If only `.basic` is enabled, queries `similarities`.
     - If only `.tags` is enabled, queries `tag_similarities`.
     - If both, it unions both result sets.
     Filters out offline users and sorts by highest similarity.
     */
    func fetchEligibleUsers(
        for currentUsername: String,
        eligibilityModes: Set<EligibilityModeOption>,
        completion: @escaping ([String]) -> Void
    ) {
        var candidates = [Candidate]()
        let group = DispatchGroup()

        func queryCollection(
            _ collection: String,
            userField: String,
            scoreField: Double,
            threshold: Double,
            flipFields: Bool
        ) {
            group.enter()
            db.collection(collection)
                .whereField(userField, isEqualTo: currentUsername)
                .whereField("similarity_score", isGreaterThanOrEqualTo: threshold)
                .getDocuments { snap, err in
                    defer { group.leave() }
                    guard let docs = snap?.documents else { return }
                    for doc in docs {
                        let data = doc.data()
                        if let other = flipFields ? data["user1_id"] as? String
                                                  : data["user2_id"] as? String,
                           let sim = data["similarity_score"] as? Double {
                            candidates.append(Candidate(username: other.trimmingCharacters(in: .whitespaces), similarity: sim))
                        }
                    }
                }
        }

        // Basic similarity
        if eligibilityModes.contains(.basic) {
            queryCollection("similarities", userField: "user1_id", scoreField: basicThreshold, threshold: basicThreshold, flipFields: false)
            queryCollection("similarities", userField: "user2_id", scoreField: basicThreshold, threshold: basicThreshold, flipFields: true)
        }
        // Tag-based similarity
        if eligibilityModes.contains(.tags) {
            queryCollection("tag_similarities", userField: "user1_id", scoreField: tagThreshold, threshold: tagThreshold, flipFields: false)
            queryCollection("tag_similarities", userField: "user2_id", scoreField: tagThreshold, threshold: tagThreshold, flipFields: true)
        }

        group.notify(queue: .main) {
            self.filterAndSort(candidates: candidates, me: currentUsername) { sortedUsernames in
                print("Eligible users for \(currentUsername): \(sortedUsernames)")
                completion(sortedUsernames)
            }
        }
    }

    /// Filters out offline users and sorts by descending similarity.
    private func filterAndSort(
        candidates: [Candidate],
        me: String,
        completion: @escaping ([String]) -> Void
    ) {
        var valid = [Candidate]()
        let innerGroup = DispatchGroup()
       
        for c in candidates {
            innerGroup.enter()
            db.collection("users").document(c.username).getDocument { snap, _ in
                defer { innerGroup.leave() }
                guard let d = snap?.data(),
                      d["isOnline"] as? Bool == true else { return }
                valid.append(c)
            }
        }

        innerGroup.notify(queue: .main) {
            // Sort by similarity and remove duplicates (keep highest sim)
            let unique = Dictionary(grouping: valid, by: { $0.username })
                .compactMap { (user, group) in group.max { $0.similarity < $1.similarity } }
                .sorted { $0.similarity > $1.similarity }
                .map { $0.username }
            completion(unique)
        }
    }
}
