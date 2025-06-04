//
//  MeView.swift
//  Morepractice
//
//  Updated 2025‑04‑22 – adds “My Favourites” button.
//

import SwiftUI
import Firebase

/// Displays the user’s profile & activity metrics.
struct MeView: View {

    // MARK: - Environment
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scoreManager: ScoreManager
    @EnvironmentObject var mediaManager: MediaManager

    // MARK: - View
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                //----------------------------------------------------------
                // Name + Username
                //----------------------------------------------------------
                Text(fullName())
                    .font(.largeTitle)
                    .bold()

                Text("@\(authViewModel.currentUser?.username ?? "")")
                    .font(.title2)
                    .foregroundColor(.gray)

                //----------------------------------------------------------
                // Top Tags
                //----------------------------------------------------------
                VStack(alignment: .leading, spacing: 5) {
                    Text("Top Tags").font(.headline)
                    if mediaManager.topTags.isEmpty {
                        Text("No tags available.").foregroundColor(.gray)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(mediaManager.topTags) { tagScore in
                                    TagView(tag: tagScore.id,
                                            score: tagScore.totalScore)
                                }
                            }
                        }
                    }
                }

                //----------------------------------------------------------
                // Basic Activity
                //----------------------------------------------------------
                VStack(alignment: .leading, spacing: 5) {
                    Text("Basic Activity").font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Uploads").font(.subheadline)
                            Text("\(authViewModel.currentUser?.totalUploads ?? 0)")
                                .font(.title3)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Total Scores").font(.subheadline)
                            Text("\(authViewModel.currentUser?.totalScores ?? 0)")
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }

                //----------------------------------------------------------
                // Navigation Buttons
                //----------------------------------------------------------
                HStack(spacing: 40) {

                    // --- MyHeart ---
                    NavigationLink(destination: MyHeartView(scoreManager: scoreManager)) {
                        VStack {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.red)
                            Text("MyHeart").font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // --- Friends ---
                    NavigationLink(destination: FriendsView()
                        .environmentObject(authViewModel)) {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.green)
                            Text("Friends").font(.caption)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // --- NEW → My Favourites ---
                    NavigationLink(destination: MyFavouritesView()
                        .environmentObject(authViewModel)) {
                        VStack {
                            ZStack {
                                Image(systemName: "heart.fill")          // red heart
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.pink)

                                Image(systemName: "sparkles")            // sparkles overlay
                                    .font(.system(size: 18))
                                    .foregroundColor(.yellow)
                                    .offset(x: -10, y: -12)
                            }
                            Text("MyFavs").font(.caption)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: MyUploadsView()
                        .environmentObject(authViewModel)
                    ) {
                        VStack {
                            Image(systemName:"person.fill.badge.plus")   // person + upload glyph
                                .resizable().frame(width:30,height:30).foregroundColor(.orange)
                            Text("My Uploads").font(.caption)
                        }
                        .padding().background(Color.orange.opacity(0.1)).cornerRadius(10)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarTitle(fullName(), displayMode: .inline)
        }
    }

    // MARK: - Helpers
    private func fullName() -> String {
        let f = authViewModel.currentUser?.firstName ?? ""
        let l = authViewModel.currentUser?.lastName  ?? ""
        return "\(f) \(l)".trimmingCharacters(in: .whitespaces)
    }

    //--------------------------------------------------------------
    // Tag cell
    //--------------------------------------------------------------
    struct TagView: View {
        let tag: String
        let score: Double
        var body: some View {
            VStack {
                Text(tag)
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                Text(String(format: "%.1f", score))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(tag), Total Score \(String(format: "%.1f", score))")
        }
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM   = AuthViewModel()
        let scoreMgr = ScoreManager(authViewModel: authVM)
        let mediaMgr = MediaManager(scoreManager: scoreMgr)

        NavigationStack {
            MeView()
                .environmentObject(authVM)
                .environmentObject(scoreMgr)
                .environmentObject(mediaMgr)
        }
    }
}
