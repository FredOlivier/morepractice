//
//  ImageManager.swift
//  Morepractice
//
//  Created by Fred Olivier on 19/09/2024.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore


struct ImagePair: Identifiable {
    var id: String  // Unique identifier for the pair
    var image1URL: String
    var image2URL: String
}

class ImageManager: ObservableObject {
    @Published var animals: [Photo] = []
    @Published var culture: [Photo] = []
    @Published var commonPairs: [ImagePair] = []
    
    private var shuffledAnimals: [Photo] = []
    private var shuffledCulture: [Photo] = []
    
    private var animalCooldown: [Photo] = []
    private var cultureCooldown: [Photo] = []
    
    // Used pairs stored as a set of unique string keys (combination of photo ids)
    private var usedPairs: Set<String> = []
    
    private let cooldownLimit = 5

    enum Category: CaseIterable {
        case animals
        case culture
    }
    
    private var scoreManager: ScoreManager
    private var db = Firestore.firestore()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(scoreManager: ScoreManager) {
        self.scoreManager = scoreManager
        fetchImages()
        fetchCommonPairs()
    }
    
    // MARK: - Fetching Images
    
    private func fetchImages() {
        // Fetch Animals
        db.collection("images").whereField("category", isEqualTo: "animals").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching animal images: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No animal images found")
                return
            }
            
            self?.animals = documents.compactMap { doc -> Photo? in
                let data = doc.data()
                if let id = data["id"] as? String,
                   let category = data["category"] as? String,
                   let url = data["url"] as? String {
                    return Photo(id: id, category: category, url: url)
                }
                return nil
            }
            
            self?.shuffledAnimals = self?.animals.shuffled() ?? []
        }
        
        // Fetch Culture
        db.collection("images").whereField("category", isEqualTo: "culture").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching culture images: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No culture images found")
                return
            }
            
            self?.culture = documents.compactMap { doc -> Photo? in
                let data = doc.data()
                if let id = data["id"] as? String,
                   let category = data["category"] as? String,
                   let url = data["url"] as? String {
                    return Photo(id: id, category: category, url: url)
                }
                return nil
            }
            
            self?.shuffledCulture = self?.culture.shuffled() ?? []
        }
    }
    
    private func fetchCommonPairs() {
        db.collection("common_pairs").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching common pairs: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No common pairs found")
                return
            }
            
            self?.commonPairs = documents.compactMap { doc -> ImagePair? in
                let data = doc.data()
                if let pair_id = data["pair_id"] as? String,
                   let image1_url = data["image1_url"] as? String,
                   let image2_url = data["image2_url"] as? String {
                    return ImagePair(id: pair_id, image1URL: image1_url, image2URL: image2_url)
                }
                return nil
            }
        }
    }
    
    // MARK: - Getting Next Pair
    
    func getNextPair(completion: @escaping ((Photo, Photo)?) -> Void) {
        let category = Category.allCases.randomElement() ?? .animals
        getPairFromSameCategory(category: category, completion: completion)
    }
    
    private func getPairFromSameCategory(category: Category, completion: @escaping ((Photo, Photo)?) -> Void) {
        // Handle each category separately without inout variables
        switch category {
        case .animals:
            // Sort animals by preference
            let sortedAnimals = sortedPhotos(shuffledAnimals)
            guard sortedAnimals.count >= 2 else {
                print("Not enough animal images to form a pair.")
                completion(nil)
                return
            }
            
            // Select two distinct random photos
            guard let firstPhoto = sortedAnimals.randomElement(),
                  let secondPhoto = sortedAnimals.filter({ $0.id != firstPhoto.id }).randomElement() else {
                completion(nil)
                return
            }
            
            // Remove selected photos from shuffledAnimals
            shuffledAnimals.removeAll { $0.id == firstPhoto.id || $0.id == secondPhoto.id }
            
            // Add to animalCooldown
            animalCooldown.append(firstPhoto)
            animalCooldown.append(secondPhoto)
            
            // Maintain cooldown lists
            if animalCooldown.count > cooldownLimit {
                animalCooldown.removeFirst(2)
            }
            
            // Create unique key
            let pairKey = "\(firstPhoto.id )-\(secondPhoto.id )"
            usedPairs.insert(pairKey)
            
            // Reshuffle if necessary
            if shuffledAnimals.count < 2 {
                reshuffle(category: .animals)
            }
            
            completion((firstPhoto, secondPhoto))
            
        case .culture:
            // Sort culture by preference
            let sortedCulture = sortedPhotos(shuffledCulture)
            guard sortedCulture.count >= 2 else {
                print("Not enough culture images to form a pair.")
                completion(nil)
                return
            }
            
            // Select two distinct random photos
            guard let firstPhoto = sortedCulture.randomElement(),
                  let secondPhoto = sortedCulture.filter({ $0.id != firstPhoto.id }).randomElement() else {
                completion(nil)
                return
            }
            
            // Remove selected photos from shuffledCulture
            shuffledCulture.removeAll { $0.id == firstPhoto.id || $0.id == secondPhoto.id }
            
            // Add to cultureCooldown
            cultureCooldown.append(firstPhoto)
            cultureCooldown.append(secondPhoto)
            
            // Maintain cooldown lists
            if cultureCooldown.count > cooldownLimit {
                cultureCooldown.removeFirst(2)
            }
            
            // Create unique key
            let pairKey = "\(firstPhoto.id )-\(secondPhoto.id )"
            usedPairs.insert(pairKey)
            
            // Reshuffle if necessary
            if shuffledCulture.count < 2 {
                reshuffle(category: .culture)
            }
            
            completion((firstPhoto, secondPhoto))
        }
    }
    
    private func sortedPhotos(_ photos: [Photo]) -> [Photo] {
        return photos.sorted {
            let preferenceA = scoreManager.imagePreference[$0.id ] ?? 0.5
            let preferenceB = scoreManager.imagePreference[$1.id ] ?? 0.5
            return preferenceA > preferenceB
        }
    }
    
    // MARK: - Reshuffling
    
    private func reshuffle(category: Category) {
        switch category {
        case .animals:
            shuffledAnimals = animals.shuffled()
        case .culture:
            shuffledCulture = culture.shuffled()
        }
    }
    
    // MARK: - Resetting Image Manager
    
    func reset() {
        reshuffle(category: .animals)
        reshuffle(category: .culture)
        animalCooldown.removeAll()
        cultureCooldown.removeAll()
        usedPairs.removeAll()
    }
    
    // MARK: - Finding Photos
    
    private func findPhotoById(id: String) -> Photo? {
        return animals.first { $0.id == id } ?? culture.first { $0.id == id }
    }
}
