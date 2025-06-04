//
//  LinkRatingView.swift
//  Morepractice
//
//  Created by Fred Olivier on 05/2025
//

import SwiftUI
import FirebaseFirestore

struct LinkRatingView: View {
  @EnvironmentObject private var appVM: AppViewModel
  @EnvironmentObject private var linkSettings: LinkingSettingsManager

  // All data passed in:
  let otherUser: String
  let snapshot: UIImage
  let sessionId: String
  let callLength: TimeInterval
  let startSimilarity: Double
  let extendedBy: TimeInterval

  @State private var rating: Double = 50
  @State private var comment: String = ""

  var body: some View {
    ZStack {
      // Snapshot background
      Image(uiImage: snapshot)
        .resizable()
        .scaledToFill()
        .edgesIgnoringSafeArea(.all)

      Color.black.opacity(0.4)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 20) {
        Spacer()

        // Rating slider
        Slider(value: $rating, in: 0...100, step: 1) { editing in
          if !editing {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          }
        }
        .accentColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.horizontal)

        // Comment box
        TextField("One word or more about them…", text: $comment)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)

        // Submit button appears once user interacts
        if rating > 0 || !comment.isEmpty {
          Button("Submit") {
            submitRating()
          }
          .font(.headline)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
          .padding(.top)
        }

        Spacer()
      }
    }
  }

  private func submitRating() {
    guard let me = appVM.authViewModel.currentUser?.username else { return }
    let db = Firestore.firestore()
    let timestamp = FieldValue.serverTimestamp()
    let data: [String: Any] = [
      "fromUid":         me,
      "toUid":           otherUser,
      "ratingValue":     Int(rating),
      "comment":         comment,
      "sessionId":       sessionId,
      "linkLength":      callLength,
      "startSimilarity": startSimilarity,
      "extendedBy":      extendedBy,
      "timestamp":       timestamp
    ]

    // Write identical document to both users' subcollections
    let refMe = db
      .collection("users")
      .document(me)
      .collection("link_ratings")
      .document(sessionId)
    let refOther = db
      .collection("users")
      .document(otherUser)
      .collection("link_ratings")
      .document(sessionId)

    let batch = db.batch()
    batch.setData(data, forDocument: refMe, merge: true)
    batch.setData(data, forDocument: refOther, merge: true)
    batch.commit { err in
      if let e = err {
        print("Error writing link rating batch:", e)
      } else {
        appVM.showRatingView = false
      }
    }
  }
}
