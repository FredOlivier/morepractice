//
//  MyFavouritesView.swift
//  Morepractice
//
//  Created by Fred Olivier on 22/04/2025.
//

import Foundation
//  MyFavouritesView.swift
//  Morepractice
//
//  Shows every favourite the user has stored.

import SwiftUI
import FirebaseFirestore

struct MyFavouritesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    private let db = Firestore.firestore()

    @State private var favourites: [MediaItem] = []
    @State private var showPreview: MediaItem?

    var body: some View {
        NavigationStack {
            List(favourites) { item in
                HStack {
                    AsyncImage(url: URL(string: item.url)) { phase in
                        switch phase {
                        case .empty:   ProgressView()
                        case .success(let img):
                            img.resizable()
                               .scaledToFill()
                               .frame(width: 90, height: 60)
                               .clipped()
                        case .failure: Color.red.frame(width: 90, height: 60)
                        @unknown default: EmptyView()
                        }
                    }
                    Text(item.id).lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { showPreview = item }
            }
            .navigationTitle("My Favourites")
            .onAppear { fetchFavourites() }
            .sheet(item: $showPreview) { media in
                AddFavouritesView(mediaItems: [media])   // simple preview
                    .environmentObject(authViewModel)
            }
        }
    }

    private func fetchFavourites() {
        guard let user = authViewModel.currentUser else { return }
        db.collection("users")
          .document(user.username)
          .collection("user_favourites")
          .getDocuments { snap, err in
              if let err = err {
                  print("MyFavouritesView: \(err.localizedDescription)")
                  return
              }
              let list = snap?.documents.compactMap { d -> MediaItem? in
                  let data = d.data()
                  guard let url = data["url"] as? String,
                        let mediaKindString = data["mediaKind"] as? String
                  else { return nil }
                  let kind: MediaKind = mediaKindString == "video" ? .video : .image
                  let cat = data["category"] as? String
                  return MediaItem(id: d.documentID,
                                   mediaKind: kind,
                                   category: cat,
                                   url: url,
                                   uploaderUid: "whowh",
                                   uploadDocPath: "sffs")
              } ?? []
              favourites = list
          }
    }
}

/* ------------------------------------------------------------------
   Add this ONE LINE inside MeView where the buttons are laid out:

   NavigationLink(destination: MyFavouritesView()
                    .environmentObject(authViewModel)) {
       VStack {
           Image(systemName: "heart.fill")
               .resizable()
               .frame(width: 30, height: 30)
               .foregroundColor(.pink)
           Text("MyFavs").font(.caption)
       }
       .padding()
       .background(Color.pink.opacity(0.1))
       .cornerRadius(10)
   }

   That keeps MeView’s existing structure intact.
------------------------------------------------------------------- */
