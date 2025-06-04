//
//  AddFavouritesView.swift
//  Morepractice
//
//  Shows the current media (1–2 items) with an “Add to my favourites”
//  button under each.  When tapped we:
//      • create / overwrite   users/{username}/user_favourites/{mediaId}
//        with the media metadata + addedAt timestamp
//      • immediately update UI with a green ✓ badge.
//  2025‑04‑22: fixed withAnimation result‑type warning.
//

import SwiftUI
import FirebaseFirestore

struct AddFavouritesView: View {
    // Media currently on‑screen
    let mediaItems: [MediaItem]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject      var authViewModel: AuthViewModel

    // Track what we’ve added this session
    @State private var addedIds: Set<String> = []

    private var db: Firestore { Firestore.firestore() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    ForEach(mediaItems) { item in
                        favouriteCard(for: item)
                    }
                }
                .padding(.vertical, 32)
            }
            .navigationTitle("Add to Favourites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Card
    @ViewBuilder
    private func favouriteCard(for item: MediaItem) -> some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: item.url)) { phase in
                switch phase {
                case .empty:   ProgressView()
                case .success(let img):
                    img.resizable()
                       .scaledToFit()
                       .frame(maxWidth: 260)
                       .cornerRadius(8)
                case .failure:
                    Color.gray.frame(width: 260, height: 180)
                        .cornerRadius(8)
                        .overlay(Text("Failed"))
                @unknown default: EmptyView()
                }
            }

            ZStack {
                Button {
                    addToFavourites(item)
                } label: {
                    Text(addedIds.contains(item.id) ? "Added" : "Add to my favourites")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(addedIds.contains(item.id) ? Color.gray.opacity(0.4)
                                                               : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(addedIds.contains(item.id))

                if addedIds.contains(item.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                        .offset(x: 140)   // right‑edge badge
                }
            }
            .frame(maxWidth: 260)
        }
    }

    // MARK: - Firestore write
    private func addToFavourites(_ item: MediaItem) {
        guard let user = authViewModel.currentUser else { return }

        let doc = db.collection("users")
                    .document(user.username)
                    .collection("user_favourites")
                    .document(item.id)

        var payload: [String: Any] = [
            "id":        item.id,
            "url":       item.url,
            "mediaKind": item.mediaKind == .image ? "image" : "video",
            "addedAt":   Timestamp(date: Date())
        ]
        if let cat = item.category { payload["category"] = cat }

        doc.setData(payload, merge: true) { err in
            if let err = err {
                print("AddFavouritesView: failed to save favourite \(item.id): \(err.localizedDescription)")
            } else {
                withAnimation {
                    _ = addedIds.insert(item.id)   // <-- discard tuple result
                }
            }
        }
    }
}

// MARK: - Preview
struct AddFavouritesView_Previews: PreviewProvider {
    static let sample = MediaItem(
        id: "sample1",
        mediaKind: .image,
        category: "culture",
        url: "https://placekitten.com/400/300",
        uploaderUid: "whowh",
        uploadDocPath: "sffs"
    )
    static var previews: some View {
        let authVM = AuthViewModel()
        NavigationStack {
            AddFavouritesView(mediaItems: [sample])
                .environmentObject(authVM)
        }
    }
}
