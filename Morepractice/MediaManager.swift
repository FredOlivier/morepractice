//
//  MediaManager.swift
//  Morepractice
//
//  26 Apr 2025  –  rev‑F
//  • catalogue fallback when single_image query empty
//  • user‑upload pair parser supports mediaURLs[2]
//  • SHA‑1 helper to fabricate IDs when absent
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import CryptoKit

// MARK: - Support types -------------------------------------------------------

enum MediaKind { case image, video }
enum InteractionType { case pair, singleImage, singleVideo, placeholder }



struct NextInteraction {
    var interactionType: InteractionType
    var media1: MediaItem?
    var media2: MediaItem?
}

private typealias ImagePair = (MediaItem,MediaItem)

// MARK: - MediaManager --------------------------------------------------------

final class MediaManager: ObservableObject {

    // ───────── published
    @Published var nextInteractionQueue:[NextInteraction] = []
    @Published var topTags:[TagScore] = []
    @Published var noMediaAvailable = false

    // ───────── catalogue pools
    private var catPairs:[ImagePair] = []
    private var catSinglesImg:[MediaItem] = []
    private var catSinglesVid:[MediaItem] = []

    // ───────── upload pools
    private var uploadPairs:[ImagePair] = []
    private var uploadSinglesImg:[MediaItem] = []
    private var uploadSinglesVid:[MediaItem] = []

    private var usedIds:Set<String> = []

    private let db = Firestore.firestore()
    private let scoreManager: ScoreManager
    private var cancellables = Set<AnyCancellable>()
    private let queueSize = 4
    private let cache = NSCache<NSString,UIImage>()

    // MARK: init ---------------------------------------------------------------
    init(scoreManager: ScoreManager) {
        self.scoreManager = scoreManager

        scoreManager.$usedMediaIds
            .sink { [weak self] ids in
                self?.usedIds = ids
                self?.filterOutUsed()
            }
            .store(in:&cancellables)

        fetchCatalogueMedia()
        fetchAllUserUploads()
        setupTopTagsListener()
    }

    // ========================================================================
    // MARK: catalogue fetch
    // ========================================================================
    private func fetchCatalogueMedia() {

        // 1. culture pairs
        db.collection("media")
          .whereField("category", isEqualTo:"culture")
          .getDocuments { [weak self] snap, err in
              guard let self = self else { return }
              if let docs = snap?.documents {
                  let imgs = docs.compactMap { d -> MediaItem? in
                      guard let id = d["id"] as? String,
                            let url = d["url"] as? String else { return nil }
                      return MediaItem(id:id, mediaKind:.image,
                                       category:"culture", url:url,
                                       uploaderUid:nil, uploadDocPath:nil)
                  }
                  self.catPairs = Self.makePairs(from:imgs)
              } else {
                  print("culture fetch error: \(err?.localizedDescription ?? "")")
              }
              self.filterOutUsed()
          }

        // 2. single_image  (primary query)
        db.collection("media")
          .whereField("mediaType", isEqualTo:"single_image")
          .getDocuments { [weak self] snap, _ in
              guard let self = self else { return }
              self.catSinglesImg = (snap?.documents ?? []).compactMap { d in
                  guard let id = d["id"] as? String,
                        let url = d["url"] as? String else { return nil }
                  return MediaItem(id:id, mediaKind:.image,
                                   category:d["category"] as? String,
                                   url:url,
                                   uploaderUid:nil, uploadDocPath:nil)
              }
              // Fallback – if query empty, use all catalogue images
              if self.catSinglesImg.isEmpty {
                  db.collection("media").getDocuments { snap2, _ in
                      self.catSinglesImg = (snap2?.documents ?? []).compactMap { d in
                          guard let id = d["id"] as? String,
                                let url = d["url"] as? String else { return nil }
                          return MediaItem(id:id, mediaKind:.image,
                                           category:d["category"] as? String,
                                           url:url,
                                           uploaderUid:nil, uploadDocPath:nil)
                      }
                      self.filterOutUsed()
                  }
              } else {
                  self.filterOutUsed()
              }
          }

        // 3. single videos
        db.collection("video_media")
          .getDocuments { [weak self] snap, _ in
              guard let self = self else { return }
              self.catSinglesVid = (snap?.documents ?? []).compactMap { d in
                  guard let id = d["id"] as? String,
                        let url = d["videoURL"] as? String else { return nil }
                  return MediaItem(id:id, mediaKind:.video,
                                   category:nil, url:url,
                                   uploaderUid:nil, uploadDocPath:nil)
              }
              self.filterOutUsed()
          }
    }

    // helper
    private static func makePairs(from imgs:[MediaItem]) -> [ImagePair] {
        var out:[ImagePair] = []
        var i = 0
        while i+1 < imgs.count { out.append((imgs[i],imgs[i+1])); i += 2 }
        return out.shuffled()
    }

    // ========================================================================
    // MARK: uploads fetch
    // ========================================================================
    private func fetchAllUserUploads() {

        let group = DispatchGroup()

        // ── pairs ───────────────────────────────────────────────────────────
        group.enter()
        db.collectionGroup("pairs").getDocuments { [weak self] snap, err in
            guard let self = self else { group.leave(); return }
            self.uploadPairs.removeAll()
            if let docs = snap?.documents {
                for d in docs {

                    // Option A – explicit fields
                    if let url1 = d["image1_url"] as? String,
                       let url2 = d["image2_url"] as? String {

                        let id1 = (d["image1_id"] as? String) ?? Self.sha1(url1)
                        let id2 = (d["image2_id"] as? String) ?? Self.sha1(url2)
                        let uploader = d.reference.parent.parent?.documentID
                        let path = d.reference.path

                        let m1 = MediaItem(id:id1, mediaKind:.image,
                                           category:nil, url:url1,
                                           uploaderUid:uploader,
                                           uploadDocPath:path)
                        let m2 = MediaItem(id:id2, mediaKind:.image,
                                           category:nil, url:url2,
                                           uploaderUid:uploader,
                                           uploadDocPath:path)
                        self.uploadPairs.append((m1,m2))
                        continue
                    }

                    // Option B – mediaURLs array
                    if let urls = d["mediaURLs"] as? [String], urls.count >= 2 {
                        let uploader = d.reference.parent.parent?.documentID
                        let path = d.reference.path
                        let m1 = MediaItem(id:Self.sha1(urls[0]), mediaKind:.image,
                                           category:nil, url:urls[0],
                                           uploaderUid:uploader,
                                           uploadDocPath:path)
                        let m2 = MediaItem(id:Self.sha1(urls[1]), mediaKind:.image,
                                           category:nil, url:urls[1],
                                           uploaderUid:uploader,
                                           uploadDocPath:path)
                        self.uploadPairs.append((m1,m2))
                    }
                }
            } else {
                print("upload‑pairs error: \(err?.localizedDescription ?? "")")
            }
            group.leave()
        }

        // ── single_upload ───────────────────────────────────────────────────
        group.enter()
        db.collectionGroup("single_upload").getDocuments { [weak self] snap, err in
            guard let self = self else { group.leave(); return }
            self.uploadSinglesImg.removeAll()
            self.uploadSinglesVid.removeAll()

            if let docs = snap?.documents {
                for d in docs {
                    let urls = (d["mediaURLs"] as? [String])
                             ?? [d["url"] as? String,
                                 d["downloadURL"] as? String].compactMap{ $0 }
                    guard let url = urls.first else { continue }

                    let kind:MediaKind
                    if let t = d["mediaType"] as? String {
                        kind = t == "video" ? .video : .image
                    } else {
                        kind = Self.kindGuess(from:url)
                    }

                    let uploader = d.reference.parent.parent?.documentID
                    let path = d.reference.path
                    let docIdField   = d["id"] as? String          // NEW
                    let chosenId     = docIdField ?? Self.sha1(url)   // <─ use it!
                    let item = MediaItem(id: chosenId, mediaKind: kind,
                                         category:nil, url:url,
                                         uploaderUid:uploader,
                                         uploadDocPath:path)
                    if kind == .video { self.uploadSinglesVid.append(item) }
                    else               { self.uploadSinglesImg.append(item) }
                }
            } else {
                print("upload‑single error: \(err?.localizedDescription ?? "")")
            }
            group.leave()
        }

        group.notify(queue:.main) {
            print("Uploads ► pairs \(self.uploadPairs.count)  singlesImg \(self.uploadSinglesImg.count)  singlesVid \(self.uploadSinglesVid.count)")
            self.filterOutUsed()
        }
    }

    private static func sha1(_ s:String) -> String {
        let data = Data(s.utf8)
        let digest = Insecure.SHA1.hash(data:data)
        return digest.map { String(format:"%02hhx",$0) }.joined()
    }

    private static func kindGuess(from url:String) -> MediaKind {
        let l = url.lowercased()
        if l.contains(".mp4") || l.contains("video/mp4") { return .video }
        return .image
    }

    // ========================================================================
    // MARK: filtering & queue
    // ========================================================================
    private func filterOutUsed() {

        let seen = usedIds

        catPairs         = catPairs.filter{ !seen.contains($0.0.id) && !seen.contains($0.1.id) }
        uploadPairs      = uploadPairs.filter{ !seen.contains($0.0.id) && !seen.contains($0.1.id) }

        catSinglesImg    = catSinglesImg.filter{ !seen.contains($0.id) }
        catSinglesVid    = catSinglesVid.filter{ !seen.contains($0.id) }
        uploadSinglesImg = uploadSinglesImg.filter{ !seen.contains($0.id) }
        uploadSinglesVid = uploadSinglesVid.filter{ !seen.contains($0.id) }

        buildQueue()
    }

    // probabilities
  /*  private let pCatPair   = 0.45
    private let pMixedPair = 0.30
    private let pUpPair    = 0.10
    private let pCatVid    = 0.10
    private let pUpVid     = 0.05
*/
    private let pCatPair   = 0.0001
      private let pMixedPair = 0.10
      private let pUpPair    = 0.0001
      private let pCatVid    = 0.90
      private let pUpVid     = 0.0001
    private func buildQueue() {

        nextInteractionQueue.removeAll()

        guard !allPoolsEmpty() else {
            noMediaAvailable = true
            nextInteractionQueue = [.init(interactionType:.placeholder,
                                          media1:nil, media2:nil)]
            return
        }
        noMediaAvailable = false

        for _ in 0..<queueSize {
            let r = Double.random(in:0...1)
            switch r {
            case 0..<pCatPair:
                if let p = catPairs.randomPop() {
                    nextInteractionQueue.append(.init(interactionType:.pair,
                                                      media1:p.0, media2:p.1))
                }
            case pCatPair ..< pCatPair+pMixedPair:
                if let p = makeMixedPair() {
                    nextInteractionQueue.append(.init(interactionType:.pair,
                                                      media1:p.0, media2:p.1))
                }
            case pCatPair+pMixedPair ..< pCatPair+pMixedPair+pUpPair:
                if let p = uploadPairs.randomPop() {
                    nextInteractionQueue.append(.init(interactionType:.pair,
                                                      media1:p.0, media2:p.1))
                }
            case pCatPair+pMixedPair+pUpPair ..< pCatPair+pMixedPair+pUpPair+pCatVid:
                if let v = catSinglesVid.randomPop() {
                    nextInteractionQueue.append(.init(interactionType:.singleVideo,
                                                      media1:v, media2:nil))
                }
            default:
                if let v = uploadSinglesVid.randomPop() {
                    nextInteractionQueue.append(.init(interactionType:.singleVideo,
                                                      media1:v, media2:nil))
                }
            }
        }

        if nextInteractionQueue.isEmpty {
            nextInteractionQueue = [.init(interactionType:.placeholder,
                                          media1:nil, media2:nil)]
            noMediaAvailable = true
        }

        prefetch()
    }

    private func makeMixedPair() -> ImagePair? {
        guard let a = catSinglesImg.randomPop(),
              let b = uploadSinglesImg.randomPop() else { return nil }
        return Bool.random() ? (a,b) : (b,a)
    }

    private func allPoolsEmpty() -> Bool {
        catPairs.isEmpty && uploadPairs.isEmpty &&
        catSinglesImg.isEmpty && uploadSinglesImg.isEmpty &&
        catSinglesVid.isEmpty && uploadSinglesVid.isEmpty
    }

    // ========================================================================
    // MARK: pop & cache
    // ========================================================================
    func popNextInteraction() -> NextInteraction? {
        if nextInteractionQueue.isEmpty { buildQueue() }
        return nextInteractionQueue.isEmpty ? nil : nextInteractionQueue.removeFirst()
    }

    private func prefetch() {
        for n in nextInteractionQueue {
            if let m = n.media1, m.mediaKind == .image { cache(url:m.url) }
            if let m = n.media2, m.mediaKind == .image { cache(url:m.url) }
        }
    }
    private func cache(url:String) {
        let k = url as NSString
        if cache.object(forKey:k) != nil { return }
        guard let u = URL(string:url) else { return }
        URLSession.shared.dataTask(with:u) { d,_,_ in
            if let d = d, let img = UIImage(data:d) { self.cache.setObject(img, forKey:k) }
        }.resume()
    }

    // ========================================================================
    // MARK: top‑tag listener (unchanged)
    // ========================================================================
    private func setupTopTagsListener() {
        scoreManager.$tagScores
            .receive(on:DispatchQueue.main)
            .sink { [weak self] dict in
                self?.topTags = Array(dict.values
                                        .sorted{ $0.totalScore > $1.totalScore }
                                        .prefix(5))
            }
            .store(in:&cancellables)
    }
}

// MARK: - Array helpers -------------------------------------------------------

private extension Array where Element == ImagePair {
    mutating func randomPop() -> ImagePair? {
        guard !isEmpty else { return nil }
        return remove(at:Int.random(in:0..<count))
    }
}
private extension Array where Element == MediaItem {
    mutating func randomPop() -> MediaItem? {
        guard !isEmpty else { return nil }
        return remove(at:Int.random(in:0..<count))
    }
}
