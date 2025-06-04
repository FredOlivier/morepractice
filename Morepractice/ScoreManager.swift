//
//  ScoreManager.swift
//  Morepractice
//
//  FULL FILE  •  2025-04-24 (debug logging build)
//
//  ▸ Tracks used_media
//  ▸ Detects & annotates scores on user-uploads
//  ▸ Updates uploader docs with running averages + ratings[]
//  ▸ Very verbose logging (🟢 success, 🟡 info, 🔴 error)
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - ScoreManager
// ---------------------------------------------------------------------------

final class ScoreManager: ObservableObject {

    // ─────────────── Published
    @Published var scores:[Score]              = []
    @Published var imagePreference:[String:Double] = [:]
    @Published var similarUsers:[AppUser]      = []
    @Published var tagScores:[String:TagScore] = [:]
    @Published var userTopTags:[TagScore]      = []
    @Published var usedMediaIds:Set<String>    = []

    // ─────────────── Private
    private let db     = Firestore.firestore()
    private let authVM :AuthViewModel
    private var bag    = Set<AnyCancellable>()

    private let similarThreshold = 0.10

    // -----------------------------------------------------------------------
    // MARK: - Init
    // -----------------------------------------------------------------------
    init(authViewModel:AuthViewModel) {
        self.authVM = authViewModel

        authVM.$currentUser
            .sink { [weak self] user in
                guard let self else { return }
                guard let cur = user else {
                    self.clearCaches()
                    return
                }
                print("🟢 ScoreManager – signed-in as \(cur.username)")
                self.listenEverything(for: cur.username)
            }
            .store(in:&bag)
    }

    private func clearCaches() {
        scores = []; imagePreference = [:]; similarUsers = []
        tagScores = [:]; userTopTags = []; usedMediaIds = []
        print("🟡 ScoreManager – caches cleared (sign-out).")
    }

    private func listenEverything(for user:String) {
        loadImagePreferences(for:user)
        observeScores(for:user)
        observeTagScores(for:user)
        fetchSimilarUsers(for:user)
        observeUsedMedia(for:user)
    }
    // ───────────────────────────────────────────────────────────────
    // 1) Add this at the bottom of ScoreManager.swift, inside the class

    /// Pulls down *every* entry in `ratings` for this doc
    /// and recomputes totalScore, ratingCount & averageScore
    private func recalcAverage(for ref: DocumentReference) {
      let myId = ref.documentID
      ref.getDocument { snap, err in
        guard
          let d = snap?.data(),
          let raw = d["ratings"] as? [[String:Any]]
        else { return }

        // for each entry, pick the one score that belongs to *this* upload:
        var scores: [Double] = []
        for e in raw {
          if let i1 = e["image1_id"] as? String,
             i1 == myId,
             let s1 = e["slider1"] as? Double {
            scores.append(s1)
          }
          else if let i2 = e["image2_id"] as? String,
                  i2 == myId,
                  let s2 = e["slider2"] as? Double {
            scores.append(s2)
          }
          else if let single = e["score"] as? Double {
            // fallback for single-media ratings
            scores.append(single)
          }
        }

        let count = scores.count
        let total = scores.reduce(0, +)
        let avg   = count > 0 ? total / Double(count) : 0

        ref.updateData([
          "totalScore":   total,
          "ratingCount":  count,
          "averageScore": avg
        ])
      }
    }


    // =========================================================================
    // MARK: -- USED MEDIA
    // =========================================================================

    private func observeUsedMedia(for user:String) {
        db.collection("users").document(user)
          .collection("used_media")
          .addSnapshotListener { [weak self] snap,err in
              guard let self else { return }
              if let err { print("🔴 used_media listener – \(err)") ; return }
              let set = Set(snap?.documents
                                .filter{ !($0.data()["reuseAllowed"] as? Bool ?? false) }
                                .map{ $0.documentID } ?? [])
              self.usedMediaIds = set
          }
    }

    private func recordUsedMediaIds(_ ids:[String]) {
        guard let user = authVM.currentUser?.username else { return }
        let col = db.collection("users").document(user).collection("used_media")
        let batch = db.batch()
        for m in ids {
            batch.setData([
                "reuseAllowed":false,
                "date":Timestamp(date:Date())
            ], forDocument:col.document(m), merge:true)
        }
        batch.commit { err in
            if let err { print("🔴 recordUsedMediaIds – \(err)") }
        }
    }

    // =========================================================================
    // MARK: -- IMAGE PREFERENCES
    // =========================================================================

    private func loadImagePreferences(for user:String) {
        db.collection("users").document(user).getDocument { [weak self] snap,err in
            guard let self else { return }
            if let err { print("🔴 load prefs – \(err)") ; return }
            let prefs = snap?.data()?["imagePreference"] as? [String:Double] ?? [:]
            self.imagePreference = prefs
        }
    }

    private func updateImagePreferences() {
        var sums:[String:(s:Double,c:Int)] = [:]
        for s in scores {
            sums[s.image1,default:(0,0)].s += s.slider1
            sums[s.image1]!.c += 1
            sums[s.image2,default:(0,0)].s += s.slider2
            sums[s.image2]!.c += 1
        }
        var out:[String:Double] = [:]
        for (k,v) in sums { out[k] = v.s / Double(v.c) }

        imagePreference = out

        if let u = authVM.currentUser?.username {
            db.collection("users").document(u).updateData(["imagePreference":out])
        }
    }

    // =========================================================================
    // MARK: -- OBSERVE SCORES (scorer’s own)
    // =========================================================================

    private func observeScores(for user:String) {
        db.collection("users").document(user)
          .collection("scores")
          .order(by:"date", descending:true)
          .addSnapshotListener { [weak self] snap,err in
              guard let self else { return }
              if let err { print("🔴 observeScores – \(err)") ; return }
              var list:[Score] = []
              snap?.documents.forEach { d in
                  let m = d.data()
                  guard
                    let s1 = m["slider1"]  as? Double,
                    let s2 = m["slider2"]  as? Double,
                    let id1 = m["image1_id"] as? String,
                    let id2 = m["image2_id"] as? String,
                    let u1  = m["image1_url"] as? String,
                    let u2  = m["image2_url"] as? String,
                    let rel = m["relational_score"] as? Double,
                    let ts  = (m["date"] as? Timestamp)?.dateValue()
                  else { return }
                  list.append(Score(id:d.documentID,
                                    slider1:s1, slider2:s2,
                                    image1:id1, image2:id2,
                                    image1URL:u1, image2URL:u2,
                                    relationalScore:rel,
                                    date:ts))
              }
              self.scores = list
              self.updateImagePreferences()
          }
    }

    // =========================================================================
    // MARK: -- TAG SCORES  (listener + helpers)
    // =========================================================================

    private func observeTagScores(for user:String) {
        db.collection("users").document(user)
          .collection("tagscores")
          .addSnapshotListener { [weak self] snap,err in
              guard let self else { return }
              if let err { print("🔴 tagScores listener – \(err)") ; return }
              var dict:[String:TagScore] = [:]
              snap?.documents.forEach { d in
                  let m = d.data()
                  let tot = m["totalScore"]  as? Double ?? 0
                  let cnt = m["ratingCount"] as? Int    ?? 0
                  dict[d.documentID] = TagScore(id:d.documentID,
                                                totalScore:tot,
                                                ratingCount:cnt)
              }
              self.tagScores   = dict
              self.userTopTags = Array(dict.values
                                        .sorted{ $0.averageScore > $1.averageScore }
                                        .prefix(5))
          }
    }

    private func updateSingleTagScore(user:String, tag:String, val:Double) {
        let ref = db.collection("users").document(user)
                    .collection("tagscores").document(tag)

        db.runTransaction({ tx,errPtr -> Any? in
              do {
                  let snap = try tx.getDocument(ref)
                  let tot  = (snap.data()?["totalScore"]  as? Double ?? 0) + val
                  let cnt  = (snap.data()?["ratingCount"] as? Int    ?? 0) + 1
                  tx.setData([
                      "totalScore":tot,
                      "ratingCount":cnt,
                      "averageScore":tot/Double(cnt)
                  ], forDocument:ref, merge:true)
                  return nil
              } catch let error as NSError {
                  errPtr?.pointee = error
                  return nil
              }
          }) { _,err in
              if let err { print("🔴 updateSingleTagScore – \(err)") }
              else       { print("🟢 updateSingleTagScore OK → \(ref.path)") }
          }
      }

    private func updateTagsForImage(user:String, imageId:String, val:Double) {
        db.collection("media").document(imageId).getDocument { [weak self] snap,_ in
            guard let self else { return }
            let tags = snap?.data()?["tags"] as? [String] ?? []
            tags.forEach { self.updateSingleTagScore(user:user, tag:$0, val:val) }
        }
    }

    // =========================================================================
    // MARK: -- USER-UPLOAD SEARCH
    // =========================================================================

    // ── ScoreManager.swift  (replace ONLY the old findUserUploadDocument)
    // MARK: -- USER-UPLOAD SEARCH  (id + url + uploaderUid inference)
    private func findUserUploadDocument(
            mediaId:  String,
            mediaURL: String,
            done:     @escaping (DocumentReference?) -> Void)
    {
        // 1)  strip any query-string and hold both flavours
        let rawURL   = mediaURL
        let cleanURL = mediaURL.split(separator: "?").first.map(String.init) ?? mediaURL
        let urlSet   = Set([rawURL, cleanURL])

        // 2)  try to pull the uploader UID straight out of the Storage path
        var hintedUid: String?
        if let r = rawURL.range(of: "/user_upload%2F") {
            let tail = rawURL[r.upperBound...]
            hintedUid = tail.split(separator:"%").first.map(String.init)
        } else if let r = rawURL.range(of: "/user_upload/") {
            let tail = rawURL[r.upperBound...]
            hintedUid = tail.split(separator:"/").first.map(String.init)
        }

        // 3)  which uploader docs should we inspect?
        let rootCol = db.collection("user_upload")
        func uidList(_ snap: QuerySnapshot?) -> [String] {
            snap?.documents.map(\.documentID) ?? []
        }

        let proceed: ( [String] ) -> Void = { uids in
            let group      = DispatchGroup()
            var found:DocumentReference?

            for uid in uids where found == nil {
                let base = rootCol.document(uid)
                for sub in ["single_upload","pairs"] where found == nil {
                    let col = base.collection(sub)

                    // (a) direct doc-id match  …/sub/<mediaId>
                    group.enter()
                    col.document(mediaId).getDocument { snap,_ in
                        if found == nil, snap?.exists == true { found = snap!.reference }
                        group.leave()
                    }

                    // (b) id field inside the doc
                    group.enter()
                    col.whereField("id", isEqualTo: mediaId).limit(to:1)
                       .getDocuments { snap,_ in
                           if found == nil, let ref = snap?.documents.first?.reference { found = ref }
                           group.leave()
                       }

                    // (c) url fields / arrays
                    for field in ["mediaURLs","url1","url2","url","downloadURL"] {
                        for candidate in urlSet {
                            group.enter()
                            col.whereField(field, isEqualTo: candidate).limit(to:1)
                               .getDocuments { snap,_ in
                                   if found == nil, let ref = snap?.documents.first?.reference { found = ref }
                                   group.leave()
                               }
                        }
                    }
                }
                if found != nil { break }
            }

            group.notify(queue:.main) {
                if let ref = found {
                    print("🟢 upload-lookup ✓  \(ref.path)")
                } else {
                    print("🔴 upload-lookup Ø  – not found")
                }
                done(found)
            }
        }

        // 4)  kick off
        if let uid = hintedUid {
            proceed([uid])                          // only that uploader – fast path
        } else {
            rootCol.getDocuments { snap,err in
                if let err { print("🔴 upload-lookup top – \(err)") ; done(nil); return }
                proceed(uidList(snap))
            }
        }
    }

    // =========================================================================
    // MARK: -- APPEND RATING
    // =========================================================================

    private func appendRating(
        to ref:DocumentReference,
        score:Double,
        scorerUid:String,
        otherMediaId:String?,
        otherMediaURL:String?
    ){
        print("🟡 appendRating → \(ref.path)  (+\(score))")
        db.runTransaction({ tx,errPtr -> Any? in
            do {
                let snap   = try tx.getDocument(ref)
                let oldTot = snap.data()?["totalScore"]  as? Double ?? 0
                let oldCnt = snap.data()?["ratingCount"] as? Int    ?? 0
                let newTot = oldTot + score
                let newCnt = oldCnt + 1
                
                tx.setData([
                    "totalScore":newTot,
                    "ratingCount":newCnt,
                    "averageScore":newTot/Double(newCnt),
                    "lastRated":Timestamp(date:Date())
                ], forDocument:ref, merge:true)
                
                var entry:[String:Any] = [
                    "scorerUid":scorerUid,
                    "score":score,
                    "ts":Timestamp(date:Date())
                ]
                if let id  = otherMediaId  { entry["otherMediaId"]  = id  }
                if let url = otherMediaURL { entry["otherMediaURL"] = url }
                
                tx.updateData([
                    "ratings":FieldValue.arrayUnion([entry])
                ], forDocument:ref)
                return nil
            } catch let error as NSError {
                errPtr?.pointee = error
                return nil
            }
        }) { [weak self] _, err in
            if let err = err {
                print("🔴 appendRating FAILED → \(err)")
            } else {
                print("🟢 appendRating OK → \(ref.path)")
                self?.recalcAverage(for: ref)
            }
        }
    }


    // =========================================================================
    // =========================================================================
    private func appendPairRating(
        to ref: DocumentReference,
        slider1: Double,
        slider2: Double,
        image1Id: String,
        image1URL: String,
        image2Id: String,
        image2URL: String,
        scorerUid: String
    ) {
        print("🟡 appendPairRating → \(ref.path)  (s1=\(slider1), s2=\(slider2))")
        db.runTransaction({ tx, errPtr -> Any? in
            do {
                // 1️⃣ Read existing totals
                let snap   = try tx.getDocument(ref)
                let oldTot = snap.data()?["totalScore"]  as? Double ?? 0
                let oldCnt = snap.data()?["ratingCount"] as? Int    ?? 0

                // 2️⃣ Compute this event’s average
                let eventAvg = (slider1 + slider2) / 2.0

                // 3️⃣ New running totals
                let newTot = oldTot + eventAvg
                let newCnt = oldCnt + 1

                // 4️⃣ Build the new rating entry
                let entry: [String:Any] = [
                    "scorerUid":  scorerUid,
                    "slider1":    Int(slider1),
                    "slider2":    Int(slider2),
                    "image1_id":  image1Id,
                    "image1_url": image1URL,
                    "image2_id":  image2Id,
                    "image2_url": image2URL,
                    "ts":         Timestamp(date: Date())
                ]

                // 5️⃣ Writes: append to array, then update totals
                tx.updateData([
                    "ratings": FieldValue.arrayUnion([entry])
                ], forDocument: ref)

                tx.setData([
                    "totalScore":   newTot,
                    "ratingCount":  newCnt,
                    "averageScore": newTot / Double(newCnt),
                    "lastRated":    Timestamp(date: Date())
                ], forDocument: ref, merge: true)

                return nil
            } catch let error as NSError {
                errPtr?.pointee = error
                return nil
            }
        }) { [weak self] _, err in
          if let err = err {
            print("🔴 appendPairRating FAILED → \(err)")
          } else {
            print("🟢 appendPairRating OK → \(ref.path)")
            self?.recalcAverage(for: ref)
          }
        }

    }

  // =========================================================================
     // MARK: -- UPDATE PAIR SCORE
     // =========================================================================
     func addScore(
         slider1: Double,
         slider2: Double,
         image1: String,
         image2: String,
         image1URL: String,
         image2URL: String,
         relationalScore: Double
     ) {
         guard let me = authVM.currentUser else { return }

         let group = DispatchGroup()
         var ref1: DocumentReference?
         var ref2: DocumentReference?

         group.enter()
         findUserUploadDocument(mediaId: image1, mediaURL: image1URL) { ref in
             ref1 = ref
             group.leave()
         }

         group.enter()
         findUserUploadDocument(mediaId: image2, mediaURL: image2URL) { ref in
             ref2 = ref
             group.leave()
         }

         group.notify(queue: .main) {
             if let r1 = ref1 {
                 self.appendPairRating(
                     to: r1,
                     slider1: slider1,
                     slider2: slider2,
                     image1Id: image1,
                     image1URL: image1URL,
                     image2Id: image2,
                     image2URL: image2URL,
                     scorerUid: me.uid
                 )
             }
             if let r2 = ref2 {
                 self.appendPairRating(
                     to: r2,
                     slider1: slider1,
                     slider2: slider2,
                     image1Id: image1,
                     image1URL: image1URL,
                     image2Id: image2,
                     image2URL: image2URL,
                     scorerUid: me.uid
                 )
             }

             // write scorer's own document
             let record: [String: Any] = [
                 "slider1": slider1,
                 "slider2": slider2,
                 "image1_id": image1,
                 "image2_id": image2,
                 "image1_url": image1URL,
                 "image2_url": image2URL,
                 "relational_score": relationalScore,
                 "date": Timestamp(date: Date())
             ]
             let scoreID = UUID().uuidString
             self.db.collection("users").document(me.username)
                 .collection("scores").document(scoreID)
                 .setData(record) { err in
                     if let err = err {
                         print("🔴 write score doc FAILED – \(err)")
                     } else {
                         print("🟢 wrote score doc \(scoreID)")
                     }
                 }
             self.recordUsedMediaIds([image1, image2])
             self.updateTagsForImage(user: me.username, imageId: image1, val: slider1)
             self.updateTagsForImage(user: me.username, imageId: image2, val: slider2)
         }
     }

    // =========================================================================
    // MARK: -- ADD SINGLE-MEDIA SCORE
    // =========================================================================

    func addSingleMediaScore(
        mediaId:String, mediaURL:String,
        sliderValue:Double, isVideo:Bool
    ){
        guard let me = authVM.currentUser else { return }

        var record:[String:Any] = [
            "mediaId":mediaId,
            "mediaURL":mediaURL,
            "sliderValue":sliderValue,
            "date":Timestamp(date:Date())
        ]

        findUserUploadDocument(mediaId:mediaId, mediaURL:mediaURL) { [weak self] ref in
            guard let self else { return }

            if let ref {
                record["isUserUpload"]    = true
                record["uploadOwnerPath"] = ref.path
                self.appendRating(to:ref, score:sliderValue,
                                  scorerUid:me.uid,
                                  otherMediaId:nil, otherMediaURL:nil)
            }

            let bucket = isVideo ? "single video scores" : "single image scores"
            let docId  = UUID().uuidString

            self.db.collection("users").document(me.username)
                .collection("single_media_scores")
                .document(bucket)
                .collection("scores")
                .document(docId)
                .setData(record) { err in
                    if let err { print("🔴 write single-media doc FAILED – \(err)") }
                    else       { print("🟢 wrote single-media doc \(docId)") }
                }

            self.recordUsedMediaIds([mediaId])

            if !isVideo {
                self.updateTagsForImage(user:me.username,
                                        imageId:mediaId,
                                        val:sliderValue)
            }
        }
    }

    func addSingleImageScore(sliderValue:Double, mediaItem:MediaItem) {
        addSingleMediaScore(mediaId:mediaItem.id, mediaURL:mediaItem.url,
                            sliderValue:sliderValue, isVideo:false)
    }
    func addSingleVideoScore(sliderValue:Double, mediaItem:MediaItem) {
        addSingleMediaScore(mediaId:mediaItem.id, mediaURL:mediaItem.url,
                            sliderValue:sliderValue, isVideo:true)
    }

    // =========================================================================
    // MARK: -- ADD SKIP
    // =========================================================================

    func addSkipScore(
        image1:String, image2:String,
        image1URL:String, image2URL:String
    ){
        guard let me = authVM.currentUser else { return }
        let docId = UUID().uuidString
        db.collection("users").document(me.username)
            .collection("scores").document(docId)
            .setData([
                "image1_id":image1, "image2_id":image2,
                "image1_url":image1URL, "image2_url":image2URL,
                "skipped":true, "date":Timestamp(date:Date())
            ])
        recordUsedMediaIds([image1,image2])
        print("🟢 skip recorded \(docId)")
    }

    // =========================================================================
    // MARK: -- SIMILAR USERS  (condensed)
    // =========================================================================

    private func fetchSimilarUsers(for user:String){
        let ref = db.collection("similarities")
        let cond = ref.whereField("similarity_score",
                                  isGreaterThanOrEqualTo:similarThreshold)
        let q1 = cond.whereField("user1_id", isEqualTo:user)
        let q2 = cond.whereField("user2_id", isEqualTo:user)

        let g = DispatchGroup(); var map:[String:Double]=[:]

        func grab(_ snap:QuerySnapshot?){
            snap?.documents.forEach{
                let d=$0.data(); let s=d["similarity_score"] as? Double ?? 0
                if let u=d["user1_id"] as? String, u != user { map[u]=max(map[u] ?? 0,s) }
                if let u=d["user2_id"] as? String, u != user { map[u]=max(map[u] ?? 0,s) }
            }
        }
        g.enter(); q1.getDocuments{ snap,_ in grab(snap); g.leave()}
        g.enter(); q2.getDocuments{ snap,_ in grab(snap); g.leave()}

        g.notify(queue:.main){
            let out = DispatchGroup(); var list:[AppUser]=[]
            for (u,sim) in map {
                out.enter()
                self.fetchUserProfile(user:u, sim:sim){ usr in
                    if let usr { list.append(usr) }
                    out.leave()
                }
            }
            out.notify(queue:.main){ self.similarUsers = list }
        }
    }

    private func fetchUserProfile(
        user:String, sim:Double,
        done:@escaping(AppUser?)->Void
    ){
        db.collection("users").document(user).getDocument { snap,_ in
            guard
              let d = snap?.data(),
              let email = d["email"] as? String,
              let online = d["isOnline"] as? Bool,
              let uid = d["uid"] as? String
            else { done(nil); return }
            done(AppUser(id:uid,name:user,email:email,
                         isOnline:online,uid:uid,
                         similarityScore:sim))
        }
    }
}
/// Recompute an upload’s totalScore/ratingCount/averageScore
/// by pulling *every* entry in its `ratings` array.
private func recalculateAverage(for ref: DocumentReference) {
  ref.getDocument { snap, err in
    guard
      let d = snap?.data(),
      let raw = d["ratings"] as? [[String:Any]]
    else { return }

    // Build a list of *per-event* averages:
    let eventAvgs: [Double] = raw.compactMap { entry in
      if let s1 = entry["slider1"] as? Double,
         let s2 = entry["slider2"] as? Double {
        return (s1 + s2) / 2.0
      } else if let score = entry["score"] as? Double {
        return score
      }
      return nil
    }

    let count = eventAvgs.count
    let total = eventAvgs.reduce(0, +)
    let avg   = count > 0 ? total/Double(count) : 0

    ref.updateData([
      "totalScore":   total,
      "ratingCount":  count,
      "averageScore": avg
    ])
  }
    
}
