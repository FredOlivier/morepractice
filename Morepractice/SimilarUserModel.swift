import Foundation

struct SimilarUser: Identifiable, Hashable {
    let id: String       // user's unique name or uid
    let name: String
    let email: String
    let isOnline: Bool
    let similarityScore: Double
    
    // Since all properties are Hashable (String, Bool, Double), SimilarUser is automatically Hashable.
    // No custom hash(into:) or == needed.
}
