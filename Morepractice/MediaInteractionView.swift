//
//  MediaInteractionView.swift
//  Morepractice
//
//  Updated 22 Apr 2025
//  • remove inline title text
//  • hide navigation title to prevent bleed-through behind transparent bars
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MediaInteractionView: View {

    @EnvironmentObject var mediaManager:          MediaManager
    @EnvironmentObject var authViewModel:         AuthViewModel
    @EnvironmentObject var settingsManager:       SettingsManager
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager

    @State private var currentInteraction: NextInteraction?

    var body: some View {
        ZStack {
            // Black background to avoid white showing through
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if let interaction = currentInteraction {
                    switch interaction.interactionType {
                    case .pair:
                        if let m1 = interaction.media1,
                           let m2 = interaction.media2 {
                            PairScoringView(media1: m1, media2: m2)
                        } else {
                            Text("Pair data malformed.")
                                .foregroundColor(.red)
                        }

                    case .singleImage:
                        if let m1 = interaction.media1 {
                            SingleImageScoringView(mediaItem: m1)
                        } else {
                            Text("No single image available.")
                                .foregroundColor(.gray)
                        }

                    case .singleVideo:
                        if let m1 = interaction.media1 {
                            SingleVideoScoringView(mediaItem: m1)
                        } else {
                            Text("No single video available.")
                                .foregroundColor(.gray)
                        }

                    case .placeholder:
                        VStack(spacing: 16) {
                            Text("More media coming!")
                                .font(.headline)
                                .padding(.top, 50)

                            Text("You’ve scored everything that’s currently available.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            Button {
                                loadNextInteraction()
                            } label: {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 40)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                } else {
                    Text("No Interaction Loaded")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("")                // hide nav title
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { firstAppear() }
    }

    // Helpers
    private func firstAppear() {
        guard let user = authViewModel.currentUser else {
            print("MediaInteractionView: ❌ no currentUser")
            return
        }
        createInteractionCountDocumentIfNeeded(for: user.username)
        loadNextInteraction()
    }

    private func loadNextInteraction() {
        let next = mediaManager.popNextInteraction()
        currentInteraction = next

        if let n = next {
            print("MediaInteractionView: received → \(n.interactionType)")
            if let m1 = n.media1 { print(" • m1 id=\(m1.id)  uploader=\(m1.uploaderUid ?? "catalogue")") }
            if let m2 = n.media2 { print(" • m2 id=\(m2.id)  uploader=\(m2.uploaderUid ?? "catalogue")") }
        }

        incrementInteractionCount()
    }

    private func createInteractionCountDocumentIfNeeded(for userName: String) {
        let ref = Firestore.firestore()
            .collection("users")
            .document(userName)
            .collection("interaction_count")
            .document("current_session")

        ref.getDocument { doc, err in
            if let err = err {
                print("interaction_count read error: \(err)")
                return
            }
            guard doc?.exists == false else { return }
            ref.setData(["count": 0]) { err in
                if let err = err { print("interaction_count create error: \(err)") }
            }
        }
    }

    private func incrementInteractionCount() {
        guard let user = authViewModel.currentUser else { return }
        let ref = Firestore.firestore()
            .collection("users")
            .document(user.username)
            .collection("interaction_count")
            .document("current_session")

        ref.setData(["count": FieldValue.increment(Int64(1))],
                    merge: true)
    }
}

struct MediaInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM   = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let mediaMgr = MediaManager(scoreManager: scoreMgr)
        let appVM    = AppViewModel()
        let setMgr   = SettingsManager()
        let linkMgr  = LinkingSettingsManager()

        NavigationStack {
            MediaInteractionView()
                .environmentObject(mediaMgr)
                .environmentObject(authVM)
                .environmentObject(setMgr)
                .environmentObject(linkMgr)
        }
    }
}
